import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../models/product_model.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final int animationIndex;

  const ProductCard({
    super.key,
    required this.product,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty =
        ref.watch(cartProvider.select((s) => s.quantityOf(product.id)));
    final isOutOfStock = product.isOutOfStock;

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 图片区域（含渐变遮罩 + 商品名叠层）──────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            color: isOutOfStock ? Colors.grey : null,
                            colorBlendMode:
                                isOutOfStock ? BlendMode.saturation : null,
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  // 底部渐变遮罩
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x70000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 商品名叠在渐变上
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Color(0x80000000),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Flash / Group badge
                  if (product.hasFlashSale)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _Badge(
                        label: '🔥 Flash',
                        color: AppColors.error,
                      ),
                    )
                  else if (product.hasGroupBuy)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _Badge(
                        label: '👥 Group',
                        color: AppColors.info,
                      ),
                    ),
                  // 售罄蒙层
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Sold Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── 价格 + 加购按钮 ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: isOutOfStock
                  ? const Text(
                      'Out of stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.hasFlashSale) ...[
                          Text(
                            '₱${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 1),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₱${product.displayPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: product.hasFlashSale
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                            if (qty == 0)
                              GestureDetector(
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .addItem(product),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 16),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QtyButton(
                                    icon: Icons.remove,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(product.id, qty - 1),
                                    filled: false,
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '$qty',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onBackground,
                                      ),
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .addItem(product),
                                    filled: true,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (50 * animationIndex).ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.border, size: 40),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QtyButton(
      {required this.icon, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: filled
              ? null
              : Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Icon(icon,
            color: filled ? Colors.white : AppColors.primary, size: 14),
      ),
    );
  }
}
