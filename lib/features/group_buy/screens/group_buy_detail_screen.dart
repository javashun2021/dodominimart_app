import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/countdown_timer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart' show addressesProvider;
import '../models/group_order_model.dart';
import '../data/group_buy_repository.dart';
import '../providers/group_buy_provider.dart';

class GroupBuyDetailScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const GroupBuyDetailScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<GroupBuyDetailScreen> createState() =>
      _GroupBuyDetailScreenState();
}

class _GroupBuyDetailScreenState
    extends ConsumerState<GroupBuyDetailScreen> {
  int _quantity = 1;
  bool _closing = false;

  String _buildShareUrl() {
    // Use web base URL for sharing
    final base = ApiEndpoints.baseUrl.replaceFirst(':8080', '');
    return '$base/group-buy/${widget.inviteCode}';
  }

  Future<void> _copyLink() async {
    final url = _buildShareUrl();
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite link copied!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _joinGroupBuy(GroupOrderModel order) async {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      context.push('/login');
      return;
    }

    final addresses = await ref.read(addressesProvider.future);
    if (!mounted) return;

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add a delivery address first'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final defaultAddr =
        addresses.where((a) => a.isDefault).firstOrNull ?? addresses.first;

    await ref.read(groupBuyActionProvider.notifier).join(
          inviteCode: widget.inviteCode,
          quantity: _quantity,
          addressId: defaultAddr.addressId,
        );

    if (!mounted) return;
    final state = ref.read(groupBuyActionProvider);
    if (state.status == GroupBuyActionStatus.success) {
      final result = state.result!;
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Group complete! Order has been placed.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating),
        );
        context.go('/orders');
      } else {
        ref.invalidate(groupOrderDetailProvider(widget.inviteCode));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Joined successfully!'),
              behavior: SnackBarBehavior.floating),
        );
      }
      ref.read(groupBuyActionProvider.notifier).reset();
    } else if (state.status == GroupBuyActionStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(state.error ?? 'Failed to join'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating),
      );
      ref.read(groupBuyActionProvider.notifier).reset();
    }
  }

  Future<void> _closeGroupBuy(GroupOrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Group Buy'),
        content: const Text(
            'Are you sure you want to close this group buy now? All current members will be included.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Close & Complete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _closing = true);
    try {
      await ref
          .read(groupBuyRepositoryProvider)
          .closeGroupOrder(widget.inviteCode);
      if (!mounted) return;
      ref.invalidate(groupOrderDetailProvider(widget.inviteCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group buy closed! Order has been placed.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/orders');
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
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync =
        ref.watch(groupOrderDetailProvider(widget.inviteCode));
    final actionState = ref.watch(groupBuyActionProvider);
    final isJoining = actionState.status == GroupBuyActionStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Buy',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _copyLink,
            tooltip: 'Copy invite link',
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) => _buildContent(context, order, isJoining),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, GroupOrderModel order, bool isJoining) {
    final progress = order.minGroupSize > 0
        ? order.currentSize / order.minGroupSize
        : 0.0;
    final isOpen = order.isOpen;

    final currentUserId = ref.read(authProvider).user?.uid;
    final isInitiator = currentUserId != null &&
        order.initiatorMemberId?.toString() == currentUserId;
    final canClose = isInitiator && order.currentSize >= order.minGroupSize;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Product header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              if (order.resolvedProductImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: order.resolvedProductImage!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgPlaceholder(),
                  ),
                )
              else
                _imgPlaceholder(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.activityTitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.info)),
                    const Gap(2),
                    Text(order.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.onBackground)),
                    const Gap(4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${order.currentPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info),
                        ),
                        if (order.originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₱${order.originalPrice!.toStringAsFixed(0)}',
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
                  ],
                ),
              ),
            ],
          ),
        ),
        const Gap(16),

        // Status + progress
        _StatusBadge(order: order),
        const Gap(12),

        if (isOpen) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.currentSize} / ${order.minGroupSize} pax',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.onBackground),
              ),
              Text(
                '${order.remaining} more needed',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.info.withValues(alpha: 0.15),
              color: AppColors.info,
            ),
          ),
          const Gap(8),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              const Text('Expires in: ',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.onSurfaceVariant)),
              CountdownTimer(endTime: order.expireTime),
            ],
          ),
          const Gap(16),
        ],

        // Price tiers
        if (order.tiers.isNotEmpty) ...[
          const Text('Price Tiers',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.onBackground)),
          const Gap(8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: order.tiers.asMap().entries.map((entry) {
                final i = entry.key;
                final tier = entry.value;
                final isLast = i == order.tiers.length - 1;
                return Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom:
                                BorderSide(color: AppColors.divider)),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Text(tier.label,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.onSurface)),
                      const Spacer(),
                      Text('₱${tier.price.toStringAsFixed(0)} / pc',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(16),
        ],

        // Members
        Text(
          'Members (${order.currentSize})',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.onBackground),
        ),
        const Gap(8),
        ...order.members.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
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
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(m.nickName,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  Text('×${m.quantity}',
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13)),
                ],
              ),
            )),
        const Gap(24),

        // Action section
        if (isOpen) ...[
          if (isInitiator) ...[
            // 发起人：只显示结束拼团按钮
            ElevatedButton.icon(
              onPressed: canClose && !_closing
                  ? () => _closeGroupBuy(order)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.success.withValues(alpha: 0.35),
              ),
              icon: _closing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(canClose
                  ? 'Close & Complete Group Buy'
                  : 'Need ${order.remaining} more to close'),
            ),
            const Gap(12),
            OutlinedButton.icon(
              onPressed: _copyLink,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Copy Invite Link'),
            ),
          ] else ...[
            // 其他人：只显示加入拼团
            Row(
              children: [
                const Text('Qty: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Text('$_quantity',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
            const Gap(8),
            ElevatedButton.icon(
              onPressed: isJoining ? null : () => _joinGroupBuy(order),
              icon: isJoining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.group_add),
              label: const Text('Join Group Buy'),
            ),
            const Gap(12),
            OutlinedButton.icon(
              onPressed: _copyLink,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Copy Invite Link'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined,
            color: AppColors.border, size: 32),
      );
}

class _StatusBadge extends StatelessWidget {
  final GroupOrderModel order;
  const _StatusBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (order.isOpen) {
      color = AppColors.info;
      label = 'Open – Accepting Members';
      icon = Icons.groups_outlined;
    } else if (order.isSuccess) {
      color = AppColors.success;
      label = 'Group Complete!';
      icon = Icons.check_circle_outline;
    } else {
      color = AppColors.error;
      label = 'Group Failed';
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
