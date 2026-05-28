import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../catalog/models/product_model.dart';

abstract class IFavoriteRepository {
  Future<List<String>> getFavoriteIds();
  Future<List<ProductModel>> getFavorites();
  Future<bool> addFavorite(String productId);
  Future<void> removeFavorite(String productId);
}

class ApiFavoriteRepository implements IFavoriteRepository {
  final ApiClient _client;
  ApiFavoriteRepository(this._client);

  @override
  Future<List<String>> getFavoriteIds() async {
    final response = await _client.get(ApiEndpoints.favoriteIds);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : [];
    return list.map((e) => e.toString()).toList();
  }

  @override
  Future<List<ProductModel>> getFavorites() async {
    final response = await _client.get(ApiEndpoints.favorites);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : [];
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> addFavorite(String productId) async {
    final response = await _client.post(ApiEndpoints.favorite(productId), data: {});
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return json['favorited'] as bool? ?? true;
  }

  @override
  Future<void> removeFavorite(String productId) async {
    final response = await _client.delete(ApiEndpoints.favorite(productId));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
  }
}

final favoriteRepositoryProvider = Provider<IFavoriteRepository>((ref) {
  return ApiFavoriteRepository(ref.watch(apiClientProvider));
});
