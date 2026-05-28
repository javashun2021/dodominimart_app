import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/review_model.dart';

abstract class IReviewRepository {
  Future<List<ReviewModel>> getProductReviews(String productId);
  Future<List<String>> getReviewedProductIds(String orderId);
  Future<void> submitReviews(
      String orderId, List<Map<String, dynamic>> reviews);
}

class ApiReviewRepository implements IReviewRepository {
  final ApiClient _client;
  ApiReviewRepository(this._client);

  @override
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    final response =
        await _client.get(ApiEndpoints.productReviews(productId));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : [];
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getReviewedProductIds(String orderId) async {
    final response =
        await _client.get(ApiEndpoints.orderReviewedIds(orderId));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : [];
    return list.map((e) => e.toString()).toList();
  }

  @override
  Future<void> submitReviews(
      String orderId, List<Map<String, dynamic>> reviews) async {
    final response = await _client.post(
      ApiEndpoints.orderReviews(orderId),
      data: {'reviews': reviews},
    );
    final json = (response.data as Map<String, dynamic>?) ?? {};
    if (json['code'] != 0) throw Exception(json['msg'] ?? 'Submit failed');
  }
}

final reviewRepositoryProvider = Provider<IReviewRepository>((ref) {
  return ApiReviewRepository(ref.watch(apiClientProvider));
});
