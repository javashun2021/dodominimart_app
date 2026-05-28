import '../../../core/constants/api_endpoints.dart';

class ReviewModel {
  final int reviewId;
  final String productId;
  final int score;
  final String? content;
  final List<String> images;
  final String memberNickname;
  final String? memberAvatar;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.score,
    this.content,
    required this.images,
    required this.memberNickname,
    this.memberAvatar,
    required this.createdAt,
  });

  String? get resolvedAvatar => ApiEndpoints.resolveImage(memberAvatar);

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        reviewId: (json['reviewId'] as num?)?.toInt() ?? 0,
        productId: json['productId']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 5,
        content: json['content'] as String?,
        images: _parseImages(json['images']),
        memberNickname: json['memberNickname'] as String? ?? 'Member',
        memberAvatar: json['memberAvatar'] as String?,
        createdAt: json['createTime'] != null
            ? DateTime.tryParse(json['createTime'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  static List<String> _parseImages(dynamic v) {
    if (v == null || v == '') return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
