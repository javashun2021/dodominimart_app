import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../../catalog/models/product_model.dart';

// ─── Cart State ───────────────────────────────────────────────────────────────

class CartState {
  final List<CartItemModel> items;

  const CartState({required this.items});

  const CartState.empty() : items = const [];

  int get totalQuantity => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => items.fold(0.0, (s, i) => s + i.subtotal);
  bool get isEmpty => items.isEmpty;

  int quantityOf(String productId) =>
      items.where((i) => i.productId == productId).firstOrNull?.quantity ?? 0;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  final SharedPreferences _prefs;
  static const _key = 'cart_items';

  CartNotifier(this._prefs) : super(const CartState.empty()) {
    _load();
  }

  void _load() {
    final stored = _prefs.getStringList(_key) ?? [];
    final items = stored
        .map((s) {
          try {
            return CartItemModel.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<CartItemModel>()
        .toList();
    state = CartState(items: items);
  }

  void _save() {
    final encoded =
        state.items.map((i) => jsonEncode(i.toJson())).toList();
    _prefs.setStringList(_key, encoded);
  }

  void addItem(ProductModel product, {int quantity = 1}) {
    final index =
        state.items.indexWhere((i) => i.productId == product.id);
    List<CartItemModel> updated;
    if (index >= 0) {
      updated = List.from(state.items);
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + quantity);
    } else {
      updated = [
        ...state.items,
        CartItemModel.fromProduct(product, quantity: quantity),
      ];
    }
    state = CartState(items: updated);
    _save();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = state.items
        .map((i) => i.productId == productId ? i.copyWith(quantity: quantity) : i)
        .toList();
    state = CartState(items: updated);
    _save();
  }

  void removeItem(String productId) {
    state = CartState(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
    _save();
  }

  void clearCart() {
    state = const CartState.empty();
    _save();
  }

  int quantityOf(String productId) {
    final item =
        state.items.where((i) => i.productId == productId).firstOrNull;
    return item?.quantity ?? 0;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

// Initialized with an override in main.dart after SharedPreferences.getInstance()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main()');
});

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(sharedPreferencesProvider));
});
