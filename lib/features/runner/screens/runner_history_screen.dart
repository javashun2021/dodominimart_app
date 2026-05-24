import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/order_status.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../orders/models/order_model.dart';
import '../providers/runner_provider.dart';

class RunnerHistoryScreen extends ConsumerWidget {
  const RunnerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(myDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myDeliveriesProvider);
          await ref.read(myDeliveriesProvider.future);
        },
        child: historyAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
          ),
          data: (allOrders) {
            // 只显示已完成（status=3）的记录，配送中的在仪表盘显示
            final orders = allOrders
                .where((o) => o.status == OrderStatus.delivered)
                .toList();
            if (orders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_outlined,
                        size: 60, color: AppColors.border),
                    Gap(12),
                    Text('No delivery history yet',
                        style:
                            TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (_, i) => _HistoryCard(order: orders[i]),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final OrderModel order;
  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final itemSummary = order.items.isEmpty
        ? 'No items'
        : order.items
                .take(2)
                .map((i) => '${i.productName} ×${i.quantity}')
                .join(', ') +
            (order.items.length > 2 ? '...' : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(order.orderNumber,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant)),
              const Spacer(),
              Text(
                '₱${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.onBackground),
              ),
            ],
          ),
          const Gap(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(order.deliveryAddress,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Gap(4),
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(itemSummary,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Gap(8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Delivered',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
