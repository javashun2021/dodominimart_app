import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/points_model.dart';

abstract class IPointsRepository {
  Future<PointsModel> getPoints();
}

class ApiPointsRepository implements IPointsRepository {
  final ApiClient _client;
  ApiPointsRepository(this._client);

  @override
  Future<PointsModel> getPoints() async {
    final response = await _client.get(ApiEndpoints.points);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return PointsModel.fromJson(json);
  }
}

final pointsRepositoryProvider = Provider<IPointsRepository>((ref) {
  return ApiPointsRepository(ref.watch(apiClientProvider));
});
