import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../cart/models/cart_item_model.dart';
import '../models/gcash_payment_info.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../../../core/enums/order_status.dart';

// ─── Interface ───────────────────────────────────────────────────────────────

abstract class IOrderRepository {
  Future<List<OrderModel>> getMyOrders();
  Future<OrderModel> getOrder(String id);
  Future<OrderModel> placeOrder(PlaceOrderRequest request);
  Future<void> cancelOrder(String id);
  Future<GCashPaymentInfo> initiatePayment(String orderId);
}

class PlaceOrderRequest {
  final int addressId;
  final String? remark;
  final List<CartItemModel> cartItems;
  final String paymentMethod; // "COD" | "GCASH"
  final int pointsToUse;

  const PlaceOrderRequest({
    required this.addressId,
    this.remark,
    required this.cartItems,
    this.paymentMethod = 'COD',
    this.pointsToUse = 0,
  });

  Map<String, dynamic> toJson() => {
        'addressId': addressId,
        'remark': remark ?? '',
        'paymentMethod': paymentMethod,
        'pointsToUse': pointsToUse,
        'items': cartItems.map((e) => {
              'productId': int.tryParse(e.productId) ?? 0,
              'quantity': e.quantity,
            }).toList(),
      };
}

// ─── Mock ─────────────────────────────────────────────────────────────────────

class MockOrderRepository implements IOrderRepository {
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'ord-001',
      orderNumber: 'DDM-20240523-0001',
      customerId: 'user-001',
      customerName: 'John Doe',
      customerPhone: '+63 912 345 6789',
      deliveryAddress: 'Block 5 Lot 12, Phase 2',
      status: OrderStatus.delivered,
      items: [
        const OrderItemModel(productId: 'p-01', productName: 'Coca-Cola 1.5L', unitPrice: 65, quantity: 2, unit: 'bottle', subtotal: 130),
        const OrderItemModel(productId: 'p-06', productName: 'Piattos Cheese 85g', unitPrice: 35, quantity: 1, unit: 'pack', subtotal: 35),
      ],
      subtotal: 165,
      deliveryFee: 20,
      total: 185,
      paymentMethod: 'cod',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    OrderModel(
      id: 'ord-002',
      orderNumber: 'DDM-20240524-0002',
      customerId: 'user-001',
      customerName: 'John Doe',
      customerPhone: '+63 912 345 6789',
      deliveryAddress: 'Block 5 Lot 12, Phase 2',
      status: OrderStatus.outForDelivery,
      items: [
        const OrderItemModel(productId: 'p-15', productName: 'Lucky Me Pancit Canton', unitPrice: 16, quantity: 3, unit: 'pack', subtotal: 48),
        const OrderItemModel(productId: 'p-04', productName: 'Milo 3-in-1 Sachet', unitPrice: 12, quantity: 5, unit: 'sachet', subtotal: 60),
      ],
      subtotal: 108,
      deliveryFee: 20,
      total: 128,
      paymentMethod: 'cod',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    OrderModel(
      id: 'ord-003',
      orderNumber: 'DDM-20240524-0003',
      customerId: 'user-001',
      customerName: 'John Doe',
      customerPhone: '+63 912 345 6789',
      deliveryAddress: 'Block 5 Lot 12, Phase 2',
      status: OrderStatus.pending,
      items: [
        const OrderItemModel(productId: 'p-10', productName: 'Safeguard White Soap 135g', unitPrice: 55, quantity: 2, unit: 'piece', subtotal: 110),
      ],
      subtotal: 110,
      deliveryFee: 20,
      total: 130,
      paymentMethod: 'cod',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];

  int _counter = 4;

  @override
  Future<List<OrderModel>> getMyOrders() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_orders.reversed);
  }

  @override
  Future<OrderModel> getOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _orders.firstWhere(
      (o) => o.id == id,
      orElse: () => throw Exception('Order not found'),
    );
  }

  @override
  Future<OrderModel> placeOrder(PlaceOrderRequest request) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final now = DateTime.now();
    final orderId = 'ord-00$_counter';
    final orderNumber =
        'DDM-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_counter.toString().padLeft(4, '0')}';
    _counter++;

    final orderItems = request.cartItems
        .map((c) => OrderItemModel(
              productId: c.productId,
              productName: c.productName,
              productImageUrl: c.productImageUrl,
              unitPrice: c.unitPrice,
              quantity: c.quantity,
              unit: c.unit,
              subtotal: c.subtotal,
            ))
        .toList();

    final subtotal = request.cartItems.fold(0.0, (s, c) => s + c.subtotal);
    const fee = ApiEndpoints.deliveryFee;

    final order = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      customerId: 'mock-001',
      customerName: 'Test User',
      customerPhone: '',
      deliveryAddress: 'Block 3, Sunrise Village',
      deliveryNotes: request.remark,
      status: OrderStatus.pending,
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      paymentMethod: request.paymentMethod,
      createdAt: now,
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<void> cancelOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _orders.indexWhere((o) => o.id == id);
    if (index < 0) throw Exception('Order not found');
  }

  @override
  Future<GCashPaymentInfo> initiatePayment(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return GCashPaymentInfo(
      referenceNo: 'MOCK-REF-$orderId',
      payUrl: 'https://gcash.com/pay?ref=MOCK-REF-$orderId',
      qrCodeUrl: null,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      amount: 0,
    );
  }
}

// ─── Real API ─────────────────────────────────────────────────────────────────

class ApiOrderRepository implements IOrderRepository {
  final ApiClient _client;

  ApiOrderRepository(this._client);

  @override
  Future<List<OrderModel>> getMyOrders() async {
    final response = await _client.get(ApiEndpoints.orders,
        params: {'pageNum': 1, 'pageSize': 100});
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final list = json['list'] as List<dynamic>? ?? [];
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<OrderModel> getOrder(String id) async {
    final response = await _client.get(ApiEndpoints.orderDetail(id));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return OrderModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<OrderModel> placeOrder(PlaceOrderRequest request) async {
    final response =
        await _client.post(ApiEndpoints.orders, data: request.toJson());
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return OrderModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> cancelOrder(String id) async {
    final response = await _client.post(ApiEndpoints.cancelOrder(id),
        data: {'reason': ''});
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
  }

  @override
  Future<GCashPaymentInfo> initiatePayment(String orderId) async {
    final response = await _client.post(
      ApiEndpoints.orderPay(orderId),
      data: {'paymentMethod': 'GCASH'},
    );
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg'] ?? 'GCash payment failed');
    return GCashPaymentInfo.fromJson(json);
  }
}
