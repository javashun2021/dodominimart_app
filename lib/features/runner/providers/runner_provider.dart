import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/models/order_model.dart';
import '../data/runner_repository.dart';
import '../models/runner_application_model.dart';

final runnerApplicationProvider =
    FutureProvider<RunnerApplicationModel>((ref) {
  return ref.watch(runnerRepositoryProvider).getApplication();
});

final availableOrdersProvider = FutureProvider<List<OrderModel>>((ref) {
  return ref.watch(runnerRepositoryProvider).getAvailableOrders();
});

final myDeliveriesProvider = FutureProvider<List<OrderModel>>((ref) {
  return ref.watch(runnerRepositoryProvider).getMyDeliveries();
});

// ─── Action notifier ─────────────────────────────────────────────────────────

enum RunnerActionStatus { idle, loading, success, error }

class RunnerActionState {
  final RunnerActionStatus status;
  final String? error;
  const RunnerActionState._({required this.status, this.error});
  const RunnerActionState.idle()    : this._(status: RunnerActionStatus.idle);
  const RunnerActionState.loading() : this._(status: RunnerActionStatus.loading);
  const RunnerActionState.success() : this._(status: RunnerActionStatus.success);
  const RunnerActionState.error(String e)
      : this._(status: RunnerActionStatus.error, error: e);
}

class RunnerActionNotifier extends StateNotifier<RunnerActionState> {
  final IRunnerRepository _repo;
  RunnerActionNotifier(this._repo) : super(const RunnerActionState.idle());

  Future<void> accept(String orderId) async {
    state = const RunnerActionState.loading();
    try {
      await _repo.acceptOrder(orderId);
      state = const RunnerActionState.success();
    } catch (e) {
      state = RunnerActionState.error(e.toString());
    }
  }

  Future<void> complete(String orderId) async {
    state = const RunnerActionState.loading();
    try {
      await _repo.completeOrder(orderId);
      state = const RunnerActionState.success();
    } catch (e) {
      state = RunnerActionState.error(e.toString());
    }
  }

  void reset() => state = const RunnerActionState.idle();
}

final runnerActionProvider =
    StateNotifierProvider<RunnerActionNotifier, RunnerActionState>((ref) {
  return RunnerActionNotifier(ref.watch(runnerRepositoryProvider));
});
