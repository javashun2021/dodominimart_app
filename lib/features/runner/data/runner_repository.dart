import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/models/order_model.dart';
import '../models/runner_application_model.dart';

abstract class IRunnerRepository {
  Future<RunnerApplicationModel> getApplication();
  Future<RunnerApplicationModel> submitApplication({
    required String realName,
    required String idNumber,
    required String phone,
    String? idPhotoUrl,
  });
  Future<List<OrderModel>> getAvailableOrders();
  Future<OrderModel> acceptOrder(String orderId);
  Future<OrderModel> completeOrder(String orderId);
  Future<List<OrderModel>> getMyDeliveries();
  Future<void> rateRunner(String orderId, int score, String? comment);
  Future<Map<String, dynamic>> getMyStats();
  Future<void> setOnlineStatus(bool isOnline);
}

class ApiRunnerRepository implements IRunnerRepository {
  final ApiClient _client;
  ApiRunnerRepository(this._client);

  @override
  Future<RunnerApplicationModel> getApplication() async {
    final response = await _client.get(ApiEndpoints.runnerApplication);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    if (data == null) return RunnerApplicationModel.none();
    return RunnerApplicationModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<RunnerApplicationModel> submitApplication({
    required String realName,
    required String idNumber,
    required String phone,
    String? idPhotoUrl,
  }) async {
    final response = await _client.post(ApiEndpoints.runnerApplication, data: {
      'realName': realName,
      'idNumber': idNumber,
      'phone': phone,
      if (idPhotoUrl != null) 'idPhotoUrl': idPhotoUrl,
    });
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return RunnerApplicationModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<OrderModel>> getAvailableOrders() async {
    final response = await _client.get(ApiEndpoints.runnerAvailableOrders);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> acceptOrder(String orderId) async {
    final response =
        await _client.post(ApiEndpoints.runnerAccept(orderId));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return OrderModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<OrderModel> completeOrder(String orderId) async {
    final response =
        await _client.post(ApiEndpoints.runnerComplete(orderId));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return OrderModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<OrderModel>> getMyDeliveries() async {
    final response = await _client.get(ApiEndpoints.runnerMyDeliveries);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> rateRunner(String orderId, int score, String? comment) async {
    final response = await _client.post(ApiEndpoints.rateRunner(orderId),
        data: {
          'score': score,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        });
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
  }

  @override
  Future<Map<String, dynamic>> getMyStats() async {
    final response = await _client.get(ApiEndpoints.runnerMyStats);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return (json['data'] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<void> setOnlineStatus(bool isOnline) async {
    final response = await _client.put(ApiEndpoints.runnerOnlineStatus,
        data: {'isOnline': isOnline});
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
  }
}

final runnerRepositoryProvider = Provider<IRunnerRepository>((ref) {
  return ApiRunnerRepository(ref.watch(apiClientProvider));
});
