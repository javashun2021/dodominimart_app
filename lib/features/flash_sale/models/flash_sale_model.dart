import '../../../core/constants/api_endpoints.dart';

class FlashSaleModel {
  final int saleId;
  final String title;
  final int productId;
  final String productName;
  final String? productImage;
  final double originalPrice;
  final double flashPrice;
  final int stockLimit;
  final int soldCount;
  final int perLimit;
  final DateTime endTime;

  const FlashSaleModel({
    required this.saleId,
    required this.title,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.originalPrice,
    required this.flashPrice,
    required this.stockLimit,
    required this.soldCount,
    required this.perLimit,
    required this.endTime,
  });

  int get stockLeft => (stockLimit - soldCount).clamp(0, stockLimit);
  double get discountPercent =>
      originalPrice > 0 ? (1 - flashPrice / originalPrice) * 100 : 0;

  String? get resolvedProductImage =>
      ApiEndpoints.resolveImage(productImage);

  factory FlashSaleModel.fromJson(Map<String, dynamic> json) => FlashSaleModel(
        saleId: (json['saleId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        productId: (json['productId'] as num?)?.toInt() ?? 0,
        productName: json['productName'] as String? ?? '',
        productImage: json['productImage'] as String?,
        originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
        flashPrice: (json['flashPrice'] as num?)?.toDouble() ?? 0.0,
        stockLimit: (json['stockLimit'] as num?)?.toInt() ?? 0,
        soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
        perLimit: (json['perLimit'] as num?)?.toInt() ?? 1,
        endTime: _parseDate(json['endTime']),
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(hours: 2));
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.now().add(const Duration(hours: 2));
    }
    return DateTime.now().add(const Duration(hours: 2));
  }
}
