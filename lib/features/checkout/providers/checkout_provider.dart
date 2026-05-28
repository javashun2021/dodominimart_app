import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/models/gcash_payment_info.dart';
import '../../orders/models/order_model.dart';
import '../../orders/providers/orders_provider.dart';

// ─── Checkout State ───────────────────────────────────────────────────────────

enum CheckoutStatus { idle, loading, success, error }

class CheckoutState {
  final CheckoutStatus status;
  final OrderModel? placedOrder;
  final GCashPaymentInfo? gcashInfo;
  final String? error;

  const CheckoutState._({
    required this.status,
    this.placedOrder,
    this.gcashInfo,
    this.error,
  });

  const CheckoutState.idle() : this._(status: CheckoutStatus.idle);
  const CheckoutState.loading() : this._(status: CheckoutStatus.loading);

  const CheckoutState.success(OrderModel order, {GCashPaymentInfo? gcashInfo})
      : this._(
          status: CheckoutStatus.success,
          placedOrder: order,
          gcashInfo: gcashInfo,
        );

  const CheckoutState.error(String error)
      : this._(status: CheckoutStatus.error, error: error);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final IOrderRepository _orderRepo;
  final CartNotifier _cart;

  CheckoutNotifier(this._orderRepo, this._cart)
      : super(const CheckoutState.idle());

  Future<void> placeOrder({
    required int addressId,
    String? remark,
    String paymentMethod = 'COD',
  }) async {
    state = const CheckoutState.loading();
    try {
      final selected = _cart.state.selectedItems;
      if (selected.isEmpty) {
        state = const CheckoutState.error('No items selected');
        return;
      }
      final request = PlaceOrderRequest(
        addressId: addressId,
        remark: remark,
        cartItems: selected,
        paymentMethod: paymentMethod.toUpperCase(),
      );
      final order = await _orderRepo.placeOrder(request);
      // Only remove selected items; unselected items remain in cart
      for (final item in selected) {
        _cart.removeItem(item.productId);
      }

      if (paymentMethod.toUpperCase() == 'GCASH') {
        final gcashInfo = await _orderRepo.initiatePayment(order.id);
        state = CheckoutState.success(order, gcashInfo: gcashInfo);
      } else {
        state = CheckoutState.success(order);
      }
    } catch (e) {
      state = CheckoutState.error(e.toString());
    }
  }

  void reset() => state = const CheckoutState.idle();
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(
    ref.watch(orderRepositoryProvider),
    ref.read(cartProvider.notifier),
  );
});
