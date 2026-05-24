import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ordersAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your order history will appear here.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (ctx, i) => _OrderTile(order: orders[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM d, yyyy · h:mm a').format(order.createdAt);

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border:
              const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                _StatusBadge(order: order),
              ],
            ),
            const Gap(6),
            Text(
              dateStr,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const Gap(8),
            Text(
              order.items
                  .map((i) => '${i.productName} ×${i.quantity}')
                  .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
              ),
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemCount} item${order.itemCount > 1 ? "s" : ""}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '₱${order.total.toStringAsFixed(0)} · COD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderModel order;

  const _StatusBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = order.status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
