import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/checkout_provider.dart';

class OrderSuccessScreen extends ConsumerWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.read(checkoutProvider).placedOrder;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                // Success icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 60,
                  ),
                ),
                const Gap(24),
                const Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const Gap(12),
                const Text(
                  'Your order has been received.\nWe\'ll deliver it to you soon!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                if (order != null) ...[
                  const Gap(28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Order Number',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Total: ₱${order.total.toStringAsFixed(0)} · Cash on Delivery',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    ref.read(checkoutProvider.notifier).reset();
                    context.go('/orders');
                  },
                  child: const Text('View My Orders'),
                ),
                const Gap(12),
                OutlinedButton(
                  onPressed: () {
                    ref.read(checkoutProvider.notifier).reset();
                    context.go('/home');
                  },
                  child: const Text('Continue Shopping'),
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
