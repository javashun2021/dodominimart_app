import 'dart:convert';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/enums/order_status.dart';
import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String? deliveryNotes;
  final OrderStatus status;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;   // "COD" | "GCASH"
  final String paymentStatus;   // "UNPAID" | "PAID" | "FAILED" | "REFUNDED"
  final String? runnerMemberId;
  final String? runnerPhone;
  final DateTime? runnerAcceptedTime;
  final String? orderSource;    // "NORMAL" | "FLASH_SALE" | "GROUP"
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.deliveryNotes,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = 'UNPAID',
    this.runnerMemberId,
    this.runnerPhone,
    this.runnerAcceptedTime,
    this.orderSource,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';
  bool get isGCash => paymentMethod.toUpperCase() == 'GCASH';

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse addressSnapshot JSON string → deliveryAddress
    String deliveryAddress = '';
    final snapshot = json['addressSnapshot'] as String?;
    if (snapshot != null && snapshot.isNotEmpty) {
      try {
        final snap = jsonDecode(snapshot) as Map<String, dynamic>;
        deliveryAddress = snap['fullAddress'] as String? ?? '';
      } catch (_) {
        deliveryAddress = snapshot;
      }
    } else {
      deliveryAddress = json['deliveryAddress'] as String? ?? '';
    }

    final total = (json['totalAmount'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ?? 0.0;
    const fee = ApiEndpoints.deliveryFee;

    final itemsList = json['items'] as List<dynamic>? ?? [];

    return OrderModel(
      id: json['orderId']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber:
          json['orderNo'] as String? ?? json['orderNumber'] as String? ?? '',
      customerId:
          json['memberId']?.toString() ?? json['customerId']?.toString() ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      deliveryAddress: deliveryAddress,
      deliveryNotes:
          json['remark'] as String? ?? json['deliveryNotes'] as String?,
      status:
          OrderStatus.fromValue(json['status']?.toString() ?? '0'),
      items: itemsList
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: total > fee ? total - fee : total,
      deliveryFee: fee,
      total: total > fee ? total : total + fee,
      paymentMethod: (json['paymentMethod'] as String?)?.toUpperCase() ?? 'COD',
      paymentStatus: (json['paymentStatus'] as String?)?.toUpperCase() ?? 'UNPAID',
      runnerMemberId: json['runnerMemberId']?.toString(),
      runnerPhone: json['runnerPhone'] as String?,
      runnerAcceptedTime: json['runnerAcceptedTime'] != null
          ? _parseDate(json['runnerAcceptedTime'])
          : null,
      orderSource: json['orderSource'] as String?,
      createdAt: _parseDate(json['createTime'] ?? json['createdAt']),
      updatedAt: json['updateTime'] != null
          ? _parseDate(json['updateTime'])
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }
}
