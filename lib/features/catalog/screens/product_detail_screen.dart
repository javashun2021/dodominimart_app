import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/countdown_timer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../main.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../group_buy/models/group_activity_model.dart';
import '../../group_buy/providers/group_buy_provider.dart';
import '../../orders/providers/orders_provider.dart' show addressesProvider;
import '../models/product_model.dart';
import '../providers/catalog_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return productAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (product) => _buildDetail(context, product),
    );
  }

  Widget _buildDetail(BuildContext context, ProductModel product) {
    final cartQty =
        ref.watch(cartProvider.select((s) => s.quantityOf(product.id)));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onBackground,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      color: product.isOutOfStock ? Colors.grey : null,
                      colorBlendMode: product.isOutOfStock
                          ? BlendMode.saturation
                          : null,
                      errorWidget: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + name
                  Text(
                    product.categoryName,
                    style: const TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 13),
                  ),
                  const Gap(4),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const Gap(8),

                  // Price section
                  if (product.hasFlashSale) ...[
                    _FlashPriceSection(product: product),
                  ] else ...[
                    Text(
                      '₱${product.price.toStringAsFixed(0)} / ${product.unit}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],

                  if (product.isOutOfStock) ...[
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const Gap(16),
                  const Divider(),
                  const Gap(16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.onBackground),
                  ),
                  const Gap(8),
                  Text(
                    product.description,
                    style: const TextStyle(
                        color: AppColors.onSurface, height: 1.6),
                  ),

                  // Group Buy section
                  if (product.hasGroupBuy) ...[
                    const Gap(20),
                    const Divider(),
                    const Gap(12),
                    _GroupBuySection(
                      activity: product.groupActivity!,
                      productId: product.id,
                    ),
                  ],

                  const Gap(32),

                  // Quantity selector
                  if (!product.isOutOfStock) ...[
                    const Text(
                      'Quantity',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.onBackground),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove,
                          onTap: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        const Gap(16),
                        Text('$_quantity',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const Gap(16),
                        _QtyButton(
                          icon: Icons.add,
                          onTap: () => setState(() => _quantity++),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ₱${(product.displayPrice * _quantity).toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                    const Gap(32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: product.isOutOfStock
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(cartProvider.notifier)
                        .addItem(product, quantity: _quantity);
                    scaffoldMessengerKey.currentState
                      ?..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('Added $_quantity × ${product.name}'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          action: SnackBarAction(
                            label: 'View Cart',
                            textColor: AppColors.secondary,
                            onPressed: () => context.push('/cart'),
                          ),
                        ),
                      );
                  },
                  icon: Icon(cartQty > 0
                      ? Icons.shopping_cart
                      : Icons.add_shopping_cart),
                  label: Text(cartQty > 0
                      ? 'Add More to Cart ($cartQty in cart)'
                      : 'Add to Cart'),
                ),
              ),
            ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.border, size: 60),
        ),
      );
}

// ── Flash Price ───────────────────────────────────────────────────────────────

class _FlashPriceSection extends StatelessWidget {
  final ProductModel product;
  const _FlashPriceSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${product.flashPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₱${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: AppColors.error),
                    const SizedBox(width: 4),
                    CountdownTimer(
                      endTime: product.flashSaleEndTime!,
                      showLabel: true,
                    ),
                    if (product.flashStockLeft != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${product.flashStockLeft} left',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group Buy Section ─────────────────────────────────────────────────────────

class _GroupBuySection extends ConsumerStatefulWidget {
  final GroupActivityModel activity;
  final String productId;

  const _GroupBuySection({required this.activity, required this.productId});

  @override
  ConsumerState<_GroupBuySection> createState() => _GroupBuySectionState();
}

class _GroupBuySectionState extends ConsumerState<_GroupBuySection> {
  bool _loading = false;

  Future<void> _startGroupBuy() async {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      context.push('/login');
      return;
    }

    setState(() => _loading = true);
    try {
      final addresses = await ref.read(addressesProvider.future);
      if (!mounted) return;

      if (addresses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a delivery address first'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final defaultAddr =
          addresses.where((a) => a.isDefault).firstOrNull ?? addresses.first;

      await ref.read(groupBuyActionProvider.notifier).start(
            activityId: widget.activity.activityId,
            quantity: 1,
            addressId: defaultAddr.addressId,
          );

      if (!mounted) return;
      final state = ref.read(groupBuyActionProvider);
      if (state.status == GroupBuyActionStatus.success) {
        final result = state.result!;
        ref.read(groupBuyActionProvider.notifier).reset();
        context.push('/group-buy/${result.inviteCode}');
      } else if (state.status == GroupBuyActionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Failed to start group buy'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(groupBuyActionProvider.notifier).reset();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.groups_outlined,
                  color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                      fontSize: 15),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'From ₱${activity.lowestPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Gap(10),
          // 价格展示：有 tiers 就显示阶梯，否则只显示 bestPrice
          if (activity.tiers.isNotEmpty) ...[
            ...activity.tiers.map((tier) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(tier.label,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.onSurface)),
                      const Spacer(),
                      Text(
                        '₱${tier.price.toStringAsFixed(0)} / pc',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info),
                      ),
                    ],
                  ),
                )),
          ] else if (activity.bestPrice != null) ...[
            Row(
              children: [
                Text(
                  '₱${activity.bestPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.info),
                ),
                const SizedBox(width: 8),
                if (activity.originalPrice != null)
                  Text(
                    '₱${activity.originalPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough),
                  ),
                const SizedBox(width: 8),
                const Text('/ pc',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.onSurfaceVariant)),
              ],
            ),
            const Gap(4),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Min ${activity.minGroupSize} people',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
          const Gap(12),
          // 发起拼团 (primary action)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _startGroupBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.group_add, size: 18),
              label: const Text('Start Group Buy'),
            ),
          ),
          const Gap(8),
          // 查看已有拼团 (secondary action)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/group-buys'),
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: const Text('View Open Groups'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: const BorderSide(color: AppColors.info),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Qty Button ───────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(
              color: onTap != null ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: onTap != null ? AppColors.primary : AppColors.border,
            size: 18),
      ),
    );
  }
}
