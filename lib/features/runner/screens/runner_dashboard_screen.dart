import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/order_status.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../orders/models/order_model.dart';
import '../data/runner_repository.dart';
import '../providers/runner_provider.dart';

class RunnerDashboardScreen extends ConsumerWidget {
  const RunnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableOrdersProvider);
    final myDeliveriesAsync = ref.watch(myDeliveriesProvider);

    // 任意一个还在 loading 就显示加载
    if (availableAsync.isLoading || myDeliveriesAsync.isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    // 优先显示错误
    final error = availableAsync.error ?? myDeliveriesAsync.error;
    if (error != null) {
      return Scaffold(
        appBar: _appBar(context, ref),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $error',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      );
    }

    final available = availableAsync.valueOrNull ?? [];
    final myDeliveries = myDeliveriesAsync.valueOrNull ?? [];

    // status=1 可接单；status=2 配送中（我的）
    final availableOrders =
        available.where((o) => o.status == OrderStatus.confirmed).toList();
    final myActive = myDeliveries
        .where((o) => o.status == OrderStatus.outForDelivery)
        .toList();

    return Scaffold(
      appBar: _appBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(availableOrdersProvider);
          ref.invalidate(myDeliveriesProvider);
          await Future.wait([
            ref.read(availableOrdersProvider.future),
            ref.read(myDeliveriesProvider.future),
          ]);
        },
        child: (myActive.isEmpty && availableOrders.isEmpty)
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delivery_dining_outlined,
                            size: 60, color: AppColors.border),
                        Gap(12),
                        Text('No orders available right now',
                            style: TextStyle(
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (myActive.isNotEmpty) ...[
                    const _SectionHeader(
                      icon: Icons.local_shipping_outlined,
                      label: 'My Active Delivery',
                      color: AppColors.info,
                    ),
                    const Gap(8),
                    ...myActive.map((o) => _OrderCard(
                          order: o,
                          isActive: true,
                        )),
                    const Gap(20),
                  ],
                  if (availableOrders.isNotEmpty) ...[
                    const _SectionHeader(
                      icon: Icons.assignment_outlined,
                      label: 'Available to Pick Up',
                      color: AppColors.onBackground,
                    ),
                    const Gap(8),
                    ...availableOrders.map((o) => _OrderCard(order: o)),
                  ],
                ],
              ),
      ),
    );
  }

  AppBar _appBar(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(onlineStatusProvider);
    final isOnline = onlineAsync.valueOrNull ?? false;

    return AppBar(
      title: const Text('Runner Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onBackground,
      surfaceTintColor: Colors.transparent,
      actions: [
        Row(
          children: [
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isOnline ? AppColors.success : AppColors.onSurfaceVariant,
              ),
            ),
            Switch(
              value: isOnline,
              activeColor: AppColors.success,
              onChanged: onlineAsync.isLoading
                  ? null
                  : (val) async {
                      try {
                        await ref
                            .read(onlineStatusProvider.notifier)
                            .toggle(val);
                        if (val) {
                          ref.invalidate(availableOrdersProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
            ),
            const SizedBox(width: 4),
          ],
        ),
        TextButton.icon(
          onPressed: () => context.push('/runner/history'),
          icon: const Icon(Icons.history, size: 18),
          label: const Text('History'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final bool isActive;
  const _OrderCard({required this.order, this.isActive = false});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _loading = false;

  void _invalidateAll() {
    ref.invalidate(availableOrdersProvider);
    ref.invalidate(myDeliveriesProvider);
  }

  Future<void> _accept() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Order'),
        content: const Text('Confirm you will deliver this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Accept')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(runnerRepositoryProvider).acceptOrder(widget.order.id);
      if (!mounted) return;
      _invalidateAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted! Go deliver it.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text(
            'Confirm the order has been delivered and you received 20 PHP from the customer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('Confirm Delivered',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(runnerRepositoryProvider)
          .completeOrder(widget.order.id);
      if (!mounted) return;
      _invalidateAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery completed!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final itemSummary = order.items.isEmpty
        ? 'No items'
        : order.items
                .take(2)
                .map((i) => '${i.productName} ×${i.quantity}')
                .join(', ') +
            (order.items.length > 2 ? '...' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isActive
              ? AppColors.info.withValues(alpha: 0.4)
              : AppColors.border,
          width: widget.isActive ? 1.5 : 1,
        ),
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
              Icon(
                widget.isActive
                    ? Icons.local_shipping
                    : Icons.assignment_outlined,
                size: 16,
                color: widget.isActive
                    ? AppColors.info
                    : AppColors.onSurfaceVariant,
              ),
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
          if (order.paymentMethod == 'COD') ...[
            const Gap(4),
            const Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 14, color: AppColors.onSurfaceVariant),
                SizedBox(width: 4),
                Text('COD + 20 PHP delivery fee',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: widget.isActive
                ? ElevatedButton.icon(
                    onPressed: _loading ? null : _complete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Confirm Delivery'),
                  )
                : ElevatedButton.icon(
                    onPressed: _loading ? null : _accept,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.delivery_dining, size: 18),
                    label: const Text("I'll Deliver This"),
                  ),
          ),
        ],
      ),
    );
  }
}
