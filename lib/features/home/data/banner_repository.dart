import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/banner_model.dart';

abstract class IBannerRepository {
  Future<List<BannerModel>> getActiveBanners();
}

class ApiBannerRepository implements IBannerRepository {
  final ApiClient _client;
  ApiBannerRepository(this._client);

  @override
  Future<List<BannerModel>> getActiveBanners() async {
    final response = await _client.get(ApiEndpoints.banners);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final bannerRepositoryProvider = Provider<IBannerRepository>((ref) {
  return ApiBannerRepository(ref.watch(apiClientProvider));
});
