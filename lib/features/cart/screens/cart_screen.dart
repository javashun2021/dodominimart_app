import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add items to get started.',
              actionLabel: 'Browse Products',
              onAction: () => context.go('/products'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemBuilder: (ctx, i) =>
                        _CartTile(item: cart.items[i]),
                  ),
                ),
                _OrderSummary(cart: cart),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart'),
        content:
            const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(cartProvider.notifier).clearCart();
    }
  }
}

class _CartTile extends ConsumerWidget {
  final CartItemModel item;

  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.productImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.productImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          const Gap(12),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  '₱${item.unitPrice.toStringAsFixed(0)} / ${item.unit}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const Gap(6),
                Text(
                  'Subtotal: ₱${item.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          // Quantity controls
          Column(
            children: [
              _QtyBtn(
                icon: Icons.add,
                onTap: () => ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.productId, item.quantity + 1),
              ),
              const Gap(6),
              Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Gap(6),
              _QtyBtn(
                icon: item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                onTap: () => ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.productId, item.quantity - 1),
                destructive: item.quantity == 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.image_outlined,
            color: AppColors.border, size: 28),
      );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _QtyBtn({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  final CartState cart;

  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const deliveryFee = ApiEndpoints.deliveryFee;
    final total = cart.subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₱${cart.subtotal.toStringAsFixed(0)}'),
              ],
            ),
            const Gap(6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery fee'),
                Text('₱${deliveryFee.toStringAsFixed(0)}'),
              ],
            ),
            const Gap(8),
            const Divider(),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '₱${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Gap(12),
            ElevatedButton(
              onPressed: () => context.push('/checkout'),
              child: const Text('Proceed to Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
