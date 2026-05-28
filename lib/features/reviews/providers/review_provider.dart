import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/review_repository.dart';
import '../models/review_model.dart';

final productReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, productId) {
  return ref.watch(reviewRepositoryProvider).getProductReviews(productId);
});

final reviewedProductIdsProvider =
    FutureProvider.family<List<String>, String>((ref, orderId) {
  return ref.watch(reviewRepositoryProvider).getReviewedProductIds(orderId);
});
