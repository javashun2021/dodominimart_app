import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_buy_repository.dart';
import '../models/group_activity_model.dart';
import '../models/group_order_model.dart';

final activeGroupActivitiesProvider =
    FutureProvider<List<GroupActivityModel>>((ref) {
  return ref.watch(groupBuyRepositoryProvider).getActiveActivities();
});

final openGroupOrdersProvider = FutureProvider<List<GroupOrderModel>>((ref) {
  return ref.watch(groupBuyRepositoryProvider).getOpenGroupOrders();
});

final groupOrdersByActivityProvider =
    FutureProvider.family<List<GroupOrderModel>, int>((ref, activityId) {
  return ref
      .watch(groupBuyRepositoryProvider)
      .getGroupOrdersByActivity(activityId);
});

final groupOrderDetailProvider =
    FutureProvider.family<GroupOrderModel, String>((ref, inviteCode) {
  return ref.watch(groupBuyRepositoryProvider).getGroupOrder(inviteCode);
});

final myGroupOrdersProvider = FutureProvider<List<GroupOrderModel>>((ref) {
  return ref.watch(groupBuyRepositoryProvider).getMyGroupOrders();
});

// ─── Start/Join group buy notifier ───────────────────────────────────────────

enum GroupBuyActionStatus { idle, loading, success, error }

class GroupBuyActionState {
  final GroupBuyActionStatus status;
  final GroupOrderModel? result;
  final String? error;

  const GroupBuyActionState._({
    required this.status,
    this.result,
    this.error,
  });

  const GroupBuyActionState.idle()
      : this._(status: GroupBuyActionStatus.idle);
  const GroupBuyActionState.loading()
      : this._(status: GroupBuyActionStatus.loading);
  const GroupBuyActionState.success(GroupOrderModel r)
      : this._(status: GroupBuyActionStatus.success, result: r);
  const GroupBuyActionState.error(String e)
      : this._(status: GroupBuyActionStatus.error, error: e);
}

class GroupBuyActionNotifier extends StateNotifier<GroupBuyActionState> {
  final IGroupBuyRepository _repo;

  GroupBuyActionNotifier(this._repo) : super(const GroupBuyActionState.idle());

  Future<void> start({
    required int activityId,
    required int quantity,
    required int addressId,
  }) async {
    state = const GroupBuyActionState.loading();
    try {
      final result = await _repo.startGroupOrder(
        activityId: activityId,
        quantity: quantity,
        addressId: addressId,
      );
      state = GroupBuyActionState.success(result);
    } catch (e) {
      state = GroupBuyActionState.error(e.toString());
    }
  }

  Future<void> join({
    required String inviteCode,
    required int quantity,
    required int addressId,
  }) async {
    state = const GroupBuyActionState.loading();
    try {
      final result = await _repo.joinGroupOrder(
        inviteCode: inviteCode,
        quantity: quantity,
        addressId: addressId,
      );
      state = GroupBuyActionState.success(result);
    } catch (e) {
      state = GroupBuyActionState.error(e.toString());
    }
  }

  Future<void> close(String inviteCode) async {
    state = const GroupBuyActionState.loading();
    try {
      await _repo.closeGroupOrder(inviteCode);
      state = const GroupBuyActionState.idle();
    } catch (e) {
      state = GroupBuyActionState.error(e.toString());
    }
  }

  void reset() => state = const GroupBuyActionState.idle();
}

final groupBuyActionProvider =
    StateNotifierProvider<GroupBuyActionNotifier, GroupBuyActionState>((ref) {
  return GroupBuyActionNotifier(ref.watch(groupBuyRepositoryProvider));
});
