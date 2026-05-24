import '../../../core/constants/api_endpoints.dart';

class PriceTier {
  final int minQuantity;
  final int? maxQuantity;
  final double price;

  const PriceTier({
    required this.minQuantity,
    this.maxQuantity,
    required this.price,
  });

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
        minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
        maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );

  String get label {
    if (maxQuantity == null) return '$minQuantity+ pax';
    return '$minQuantity–$maxQuantity pax';
  }
}

class GroupActivityModel {
  final int activityId;
  final String title;
  final int productId;
  final String productName;
  final String? productImage;
  final int minGroupSize;
  final int durationHours;
  final DateTime startTime;
  final DateTime endTime;
  final List<PriceTier> tiers;
  final double? originalPrice;  // 原价
  final double? bestPrice;      // 最优拼团价（最低档）

  const GroupActivityModel({
    required this.activityId,
    required this.title,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.minGroupSize,
    required this.durationHours,
    required this.startTime,
    required this.endTime,
    required this.tiers,
    this.originalPrice,
    this.bestPrice,
  });

  String? get resolvedProductImage =>
      ApiEndpoints.resolveImage(productImage);

  /// 展示用的最优价格：bestPrice 优先，其次取 tiers 最低价
  double get lowestPrice {
    if (bestPrice != null) return bestPrice!;
    if (tiers.isEmpty) return 0;
    return tiers.map((t) => t.price).reduce((a, b) => a < b ? a : b);
  }

  factory GroupActivityModel.fromJson(Map<String, dynamic> json) =>
      GroupActivityModel(
        activityId: (json['activityId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        productId: (json['productId'] as num?)?.toInt() ?? 0,
        productName: json['productName'] as String? ?? '',
        productImage: json['productImage'] as String?,
        minGroupSize: (json['minGroupSize'] as num?)?.toInt() ?? 2,
        durationHours: (json['durationHours'] as num?)?.toInt() ?? 24,
        startTime: _parseDate(json['startTime']),
        endTime: _parseDate(json['endTime']),
        tiers: (json['tiers'] as List<dynamic>? ?? [])
            .map((e) => PriceTier.fromJson(e as Map<String, dynamic>))
            .toList(),
        originalPrice: (json['originalPrice'] as num?)?.toDouble(),
        bestPrice: (json['bestPrice'] as num?)?.toDouble(),
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
