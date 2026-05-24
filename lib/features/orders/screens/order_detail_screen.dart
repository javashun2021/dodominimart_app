import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/order_status.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../runner/data/runner_repository.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return orderAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (order) => _OrderDetailView(order: order),
    );
  }
}

class _OrderDetailView extends ConsumerWidget {
  final OrderModel order;

  const _OrderDetailView({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status stepper
          _StatusStepper(currentStatus: order.status),
          const Gap(20),

          // Delivery info
          _Section(
            title: 'Delivery Info',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.phone_outlined, text: order.customerPhone),
                const Gap(8),
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: order.deliveryAddress),
                if (order.deliveryNotes != null) ...[
                  const Gap(8),
                  _InfoRow(
                    icon: Icons.note_outlined,
                    text: order.deliveryNotes!,
                  ),
                ],
              ],
            ),
          ),
          const Gap(16),

          // Items
          _Section(
            title: 'Items',
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} × ${item.quantity} ${item.unit}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '₱${item.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const Gap(16),

          // Price breakdown
          _Section(
            title: 'Payment',
            child: Column(
              children: [
                _PriceRow(label: 'Subtotal', value: order.subtotal),
                const Gap(6),
                _PriceRow(label: 'Delivery fee', value: order.deliveryFee),
                const Divider(height: 16),
                _PriceRow(
                  label: 'Total',
                  value: order.total,
                  bold: true,
                ),
                const Gap(8),
                const Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        color: AppColors.success, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rate Runner section
          if (order.status == OrderStatus.delivered &&
              order.runnerMemberId != null) ...[
            const Gap(16),
            _RateRunnerSection(order: order),
          ],

          // Cancel button
          if (order.status.canCancel) ...[
            const Gap(24),
            OutlinedButton(
              onPressed: () => _confirmCancel(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Cancel Order'),
            ),
          ],
          const Gap(32),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(orderRepositoryProvider).cancelOrder(order.id);
        ref.invalidate(myOrdersProvider);
        ref.invalidate(orderDetailProvider(order.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _RateRunnerSection extends ConsumerStatefulWidget {
  final OrderModel order;
  const _RateRunnerSection({required this.order});

  @override
  ConsumerState<_RateRunnerSection> createState() => _RateRunnerSectionState();
}

class _RateRunnerSectionState extends ConsumerState<_RateRunnerSection> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating first')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(runnerRepositoryProvider).rateRunner(
            widget.order.id,
            _stars,
            _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _submitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted, thank you!'),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _Section(
        title: 'Runner Rating',
        child: Row(
          children: [
            ...List.generate(
              5,
              (i) => Icon(
                i < _stars ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Thanks for your feedback!',
                style:
                    TextStyle(color: AppColors.success, fontSize: 13)),
          ],
        ),
      );
    }

    return _Section(
      title: 'Rate Your Runner',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How was your delivery experience?',
              style: TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant)),
          const Gap(12),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    i < _stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const Gap(12),
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Leave a comment (optional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Rating'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final OrderStatus currentStatus;

  const _StatusStepper({required this.currentStatus});

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: 10),
            Text(
              'Order Cancelled',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(currentStatus);

    return Row(
      children: _steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isDone = i <= currentIndex;
        final isLast = i == _steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: isDone ? 16 : 8,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isDone
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDone
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < currentIndex
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.onBackground,
            ),
          ),
          const Gap(10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
        Text(
          '₱${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 18 : 14,
            color: bold ? AppColors.primary : AppColors.onBackground,
          ),
        ),
      ],
    );
  }
}
