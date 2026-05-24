import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/group_activity_model.dart';
import '../models/group_order_model.dart';

abstract class IGroupBuyRepository {
  Future<List<GroupActivityModel>> getActiveActivities();
  Future<List<GroupOrderModel>> getOpenGroupOrders();
  Future<List<GroupOrderModel>> getGroupOrdersByActivity(int activityId);
  Future<GroupOrderModel> getGroupOrder(String inviteCode);
  Future<GroupOrderModel> startGroupOrder({
    required int activityId,
    required int quantity,
    required int addressId,
  });
  Future<GroupOrderModel> joinGroupOrder({
    required String inviteCode,
    required int quantity,
    required int addressId,
  });
  Future<void> closeGroupOrder(String inviteCode);
  Future<List<GroupOrderModel>> getMyGroupOrders({String? status});
}

class ApiGroupBuyRepository implements IGroupBuyRepository {
  final ApiClient _client;
  ApiGroupBuyRepository(this._client);

  @override
  Future<List<GroupActivityModel>> getActiveActivities() async {
    final response = await _client.get(ApiEndpoints.groupActivities);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => GroupActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<GroupOrderModel>> getOpenGroupOrders() async {
    final response = await _client.post(ApiEndpoints.groupOrdersList, data: {
      'status': '0',
      'pageNum': 1,
      'pageSize': 50,
    });
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => GroupOrderModel.fromJson({
              'data': e as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<GroupOrderModel>> getGroupOrdersByActivity(int activityId) async {
    final response = await _client.get(ApiEndpoints.groupOrders,
        params: {'activityId': activityId});
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => GroupOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupOrderModel> getGroupOrder(String inviteCode) async {
    final response =
        await _client.get(ApiEndpoints.groupOrderDetail(inviteCode));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return GroupOrderModel.fromJson(json);
  }

  @override
  Future<GroupOrderModel> startGroupOrder({
    required int activityId,
    required int quantity,
    required int addressId,
  }) async {
    final response = await _client.post(ApiEndpoints.groupOrders, data: {
      'activityId': activityId,
      'quantity': quantity,
      'addressId': addressId,
    });
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return GroupOrderModel.fromJson(json);
  }

  @override
  Future<GroupOrderModel> joinGroupOrder({
    required String inviteCode,
    required int quantity,
    required int addressId,
  }) async {
    final response = await _client.post(
      ApiEndpoints.joinGroupOrder(inviteCode),
      data: {'quantity': quantity, 'addressId': addressId},
    );
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return GroupOrderModel.fromJson(json);
  }

  @override
  Future<void> closeGroupOrder(String inviteCode) async {
    final response = await _client.post(ApiEndpoints.closeGroupOrder(inviteCode));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
  }

  @override
  Future<List<GroupOrderModel>> getMyGroupOrders({String? status}) async {
    final response = await _client.get(ApiEndpoints.myGroupOrders, params: {
      if (status != null) 'status': status,
      'pageNum': 1,
      'pageSize': 50,
    });
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['list'] as List? ?? [];
    return list
        .map((e) => GroupOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final groupBuyRepositoryProvider = Provider<IGroupBuyRepository>((ref) {
  return ApiGroupBuyRepository(ref.watch(apiClientProvider));
});
