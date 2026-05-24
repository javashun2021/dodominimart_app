import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../models/product_model.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

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
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 2),
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
            // Image with optional flash badge
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
                  if (product.hasFlashSale)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🔥 Flash',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (product.hasGroupBuy)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '👥 Group',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (isOutOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Out of stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Column(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.border, size: 40),
        ),
      );
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
