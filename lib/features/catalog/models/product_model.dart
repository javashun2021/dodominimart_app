import '../../../core/constants/api_endpoints.dart';
import '../../group_buy/models/group_activity_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double price;
  final String? imageUrl;
  final int stock;
  final bool isAvailable;
  final bool isFeatured;
  final String unit;
  final List<String> tags;

  // Flash Sale fields (null = no active flash sale)
  final double? flashPrice;
  final DateTime? flashSaleEndTime;
  final int? flashStockLeft;

  // Group Buy (null = no active group buy activity)
  final GroupActivityModel? groupActivity;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    this.imageUrl,
    required this.stock,
    required this.isAvailable,
    required this.isFeatured,
    required this.unit,
    required this.tags,
    this.flashPrice,
    this.flashSaleEndTime,
    this.flashStockLeft,
    this.groupActivity,
  });

  bool get isOutOfStock => stock <= 0 || !isAvailable;
  bool get hasFlashSale => flashPrice != null && flashSaleEndTime != null;
  bool get hasGroupBuy => groupActivity != null;

  /// The price shown to users (flash price if active, else regular price).
  double get displayPrice => flashPrice ?? price;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse flash sale end time
    DateTime? flashEnd;
    final flashEndRaw = json['flashSaleEndTime'];
    if (flashEndRaw != null) {
      flashEnd = DateTime.tryParse(flashEndRaw.toString());
    }

    // Parse group activity
    GroupActivityModel? groupActivity;
    final ga = json['groupActivity'];
    if (ga is Map<String, dynamic>) {
      groupActivity = GroupActivityModel.fromJson(ga);
    }

    return ProductModel(
      id: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: ApiEndpoints.resolveImage(json['imageUrl'] as String?),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isAvailable: json['status'] == '0' || (json['isAvailable'] as bool? ?? true),
      isFeatured: json['isFeatured'] as bool? ?? false,
      unit: json['unit'] as String? ?? 'piece',
      tags: List<String>.from(json['tags'] ?? []),
      flashPrice: (json['flashPrice'] as num?)?.toDouble(),
      flashSaleEndTime: flashEnd,
      flashStockLeft: (json['flashStockLeft'] as num?)?.toInt(),
      groupActivity: groupActivity,
    );
  }
}
