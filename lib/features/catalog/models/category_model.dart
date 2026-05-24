import '../../../core/constants/api_endpoints.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['categoryId']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        imageUrl: ApiEndpoints.resolveImage(
            json['iconUrl'] as String? ?? json['imageUrl'] as String?),
        sortOrder: (json['sort'] as num?)?.toInt() ??
            (json['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: json['status'] == '0' || (json['isActive'] as bool? ?? true),
      );
}
