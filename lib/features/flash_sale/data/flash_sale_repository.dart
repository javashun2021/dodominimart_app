import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/flash_sale_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IFlashSaleRepository {
  Future<List<FlashSaleModel>> getActiveFlashSales();
}

class ApiFlashSaleRepository implements IFlashSaleRepository {
  final ApiClient _client;
  ApiFlashSaleRepository(this._client);

  @override
  Future<List<FlashSaleModel>> getActiveFlashSales() async {
    final response = await _client.get(ApiEndpoints.flashSales);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => FlashSaleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final flashSaleRepositoryProvider = Provider<IFlashSaleRepository>((ref) {
  return ApiFlashSaleRepository(ref.watch(apiClientProvider));
});
