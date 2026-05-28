import '../../../core/constants/api_endpoints.dart';

enum BannerLinkType { none, product, group, url }

class BannerModel {
  final int bannerId;
  final String imageUrl;
  final BannerLinkType linkType;
  final String? linkValue;
  final int sort;

  const BannerModel({
    required this.bannerId,
    required this.imageUrl,
    required this.linkType,
    this.linkValue,
    required this.sort,
  });

  String get resolvedImageUrl => ApiEndpoints.resolveImage(imageUrl) ?? imageUrl;

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        bannerId: (json['bannerId'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl'] as String? ?? '',
        linkType: _parseLinkType(json['linkType'] as String?),
        linkValue: json['linkValue'] as String?,
        sort: (json['sort'] as num?)?.toInt() ?? 0,
      );

  static BannerLinkType _parseLinkType(String? v) => switch (v) {
        'PRODUCT' => BannerLinkType.product,
        'GROUP'   => BannerLinkType.group,
        'URL'     => BannerLinkType.url,
        _         => BannerLinkType.none,
      };
}
