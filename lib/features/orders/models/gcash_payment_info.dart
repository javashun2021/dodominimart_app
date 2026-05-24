import '../../../core/constants/api_endpoints.dart';

class GCashPaymentInfo {
  final String referenceNo;
  final String payUrl;
  final String? qrCodeUrl;
  final DateTime expiresAt;
  final double amount;

  const GCashPaymentInfo({
    required this.referenceNo,
    required this.payUrl,
    this.qrCodeUrl,
    required this.expiresAt,
    required this.amount,
  });

  String? get resolvedQrCodeUrl => ApiEndpoints.resolveImage(qrCodeUrl);

  factory GCashPaymentInfo.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return GCashPaymentInfo(
      referenceNo: data['referenceNo'] as String? ?? '',
      payUrl: data['paymentUrl'] as String? ?? data['payUrl'] as String? ?? '',
      qrCodeUrl: data['qrCodeUrl'] as String?,
      expiresAt: _parseDate(data['expireTime'] ?? data['expiresAt']),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(minutes: 15));
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now().add(const Duration(minutes: 15));
    return DateTime.now().add(const Duration(minutes: 15));
  }
}
