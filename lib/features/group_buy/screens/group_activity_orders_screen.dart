import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/countdown_timer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart' show addressesProvider;
import '../models/group_activity_model.dart';
import '../models/group_order_model.dart';
import '../providers/group_buy_provider.dart';

class GroupActivityOrdersScreen extends ConsumerStatefulWidget {
  final GroupActivityModel activity;

  const GroupActivityOrdersScreen({super.key, required this.activity});

  @override
  ConsumerState<GroupActivityOrdersScreen> createState() =>
      _GroupActivityOrdersScreenState();
}

class _GroupActivityOrdersScreenState
    extends ConsumerState<GroupActivityOrdersScreen> {
  bool _starting = false;

  Future<void> _startNew() async {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      context.push('/login');
      return;
    }

    setState(() => _starting = true);
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
        ref.invalidate(groupOrdersByActivityProvider(widget.activity.activityId));
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
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final ordersAsync =
        ref.watch(groupOrdersByActivityProvider(activity.activityId));

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // 价格信息 + 发起按钮
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.onBackground)),
                const Gap(6),
                if (activity.tiers.isNotEmpty)
                  ...activity.tiers.map((tier) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline,
                                size: 14,
                                color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(tier.label,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onSurface)),
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
                      ))
                else
                  Row(
                    children: [
                      Text(
                        '₱${activity.lowestPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info),
                      ),
                      if (activity.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₱${activity.originalPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Text('/ pc',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _starting ? null : _startNew,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                    ),
                    icon: _starting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.group_add, size: 18),
                    label: const Text('Start New Group Buy'),
                  ),
                ),
              ],
            ),
          ),

          // 开放中的拼团列表
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.groups_outlined,
                    size: 16, color: AppColors.onSurfaceVariant),
                SizedBox(width: 6),
                Text('Open Groups — join one below',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Gap(8),

          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No open groups yet — start one!',
                        style:
                            TextStyle(color: AppColors.onSurfaceVariant)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (_, i) => _GroupOrderTile(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupOrderTile extends StatelessWidget {
  final GroupOrderModel order;
  const _GroupOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final progress = order.minGroupSize > 0
        ? order.currentSize / order.minGroupSize
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/group-buy/${order.inviteCode}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 成员头像堆叠
                _MemberAvatars(members: order.members),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.members.isNotEmpty
                            ? order.members.first.nickName
                            : 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.onBackground),
                      ),
                      Text(
                        '${order.currentSize} member${order.currentSize != 1 ? 's' : ''} · ${order.remaining} more needed',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${order.currentPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info),
                    ),
                    const Text('/ pc',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const Gap(10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.info.withValues(alpha: 0.15),
                color: AppColors.info,
              ),
            ),
            const Gap(6),
            Row(
              children: [
                Text(
                  '${order.currentSize} / ${order.minGroupSize} pax',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const Spacer(),
                const Icon(Icons.timer_outlined,
                    size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                CountdownTimer(
                  endTime: order.expireTime,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  final List<GroupMember> members;
  const _MemberAvatars({required this.members});

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();
    const size = 34.0;
    const overlap = 10.0;

    return SizedBox(
      width: size + (shown.length - 1).clamp(0, 2) * (size - overlap),
      height: size,
      child: Stack(
        children: shown.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: AppColors.info.withValues(alpha: 0.2),
                backgroundImage: m.resolvedAvatar != null
                    ? NetworkImage(m.resolvedAvatar!)
                    : null,
                child: m.resolvedAvatar == null
                    ? Text(
                        m.nickName.isNotEmpty
                            ? m.nickName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
