import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../features/auth/models/address_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/order_repository.dart';
import '../models/order_model.dart';

const _useMock = false;

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  if (_useMock) return MockOrderRepository();
  return ApiOrderRepository(ref.watch(apiClientProvider));
});

// ─── My Orders list ───────────────────────────────────────────────────────────

final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).getMyOrders();
});

// ─── Single order detail ──────────────────────────────────────────────────────

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).getOrder(id);
});

// ─── Member addresses (used in checkout) ─────────────────────────────────────

final addressesProvider = FutureProvider<List<AddressModel>>((ref) async {
  if (_useMock) {
    return [
      const AddressModel(
        addressId: 1,
        label: 'Home',
        fullAddress: 'Block 3, Lot 5, Sunrise Village, Batangas',
        isDefault: true,
      ),
    ];
  }
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.memberAddresses);
  final json = response.data!;
  if (json['code'] != 0) throw Exception(json['msg']);
  final list = (json['data'] ?? json['list']) as List<dynamic>? ?? [];
  return list
      .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
