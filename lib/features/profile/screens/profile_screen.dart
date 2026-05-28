import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../runner/models/runner_application_model.dart';
import '../../runner/providers/runner_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final config = ref.watch(appConfigProvider).valueOrNull;
    final addresses = ref.watch(addressesProvider).valueOrNull ?? [];
    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull
        ?? (addresses.isNotEmpty ? addresses.first : null);
    final runnerAsync = ref.watch(runnerApplicationProvider);
    final isApprovedRunner = runnerAsync.valueOrNull?.isApproved == true;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 渐变头像卡片 ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8540), Color(0xFFC2410C)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // 装饰圆圈
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // 主内容
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    child: Column(
                      children: [
                        // 头像
                        GestureDetector(
                          onTap: () => context.push('/edit-profile'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                                backgroundImage: user.avatar != null &&
                                        user.avatar!.isNotEmpty
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                child:
                                    (user.avatar == null || user.avatar!.isEmpty)
                                        ? Text(
                                            user.nickname.isNotEmpty
                                                ? user.nickname[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                              ),
                              // 编辑图标
                              Positioned(
                                top: 0,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: 0.15),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.edit,
                                      color: AppColors.primary, size: 13),
                                ),
                              ),
                              // Runner 角标
                              if (isApprovedRunner)
                                Positioned(
                                  bottom: 0,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delivery_dining,
                                            color: Colors.white, size: 11),
                                        SizedBox(width: 3),
                                        Text('Runner',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Gap(14),
                        Text(
                          user.nickname,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(3),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        // Runner 快捷按钮
                        if (isApprovedRunner) ...[
                          const Gap(18),
                          Row(
                            children: [
                              Expanded(
                                child: _RunnerCardButton(
                                  icon: Icons.delivery_dining,
                                  label: 'Available Orders',
                                  onTap: () => context.push('/runner'),
                                  filled: true,
                                ),
                              ),
                              const Gap(10),
                              Expanded(
                                child: _RunnerCardButton(
                                  icon: Icons.history,
                                  label: 'Delivery History',
                                  onTap: () =>
                                      context.push('/runner/history'),
                                  filled: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Gap(16),

          // ── Info tiles（Phone + Address 合并）────────────────────────────
          _CombinedInfoTile(
            phone: user.phoneNumber ?? 'Not set',
            address: defaultAddress?.fullAddress ?? 'Not set',
            onEditAddress: () => context.push('/addresses'),
          ),

          const Gap(16),

          // ── My Favourites ────────────────────────────────────────────────
          _SectionLabel('Shopping'),
          const Gap(10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _MenuTile(
              icon: Icons.favorite_border_rounded,
              iconColor: Colors.red[400]!,
              label: 'My Favourites',
              onTap: () => context.push('/favorites'),
              isFirst: true,
              isLast: true,
            ),
          ),
          const Gap(16),

          // ── Contact Us ───────────────────────────────────────────────────
          if (config != null &&
              (config.contactPhone.isNotEmpty ||
                  config.messengerLink.isNotEmpty)) ...[
            _SectionLabel('Contact Us'),
            const Gap(10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (config.contactPhone.isNotEmpty)
                    _ContactTile(
                      icon: Icons.phone_outlined,
                      label: 'Call Us',
                      value: config.contactPhone,
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${config.contactPhone}')),
                      isFirst: true,
                      isLast: config.messengerLink.isEmpty,
                    ),
                  if (config.contactPhone.isNotEmpty &&
                      config.messengerLink.isNotEmpty)
                    const Divider(
                        height: 1,
                        indent: 52,
                        color: AppColors.divider),
                  if (config.messengerLink.isNotEmpty)
                    _ContactTile(
                      icon: Icons.chat_bubble_outline,
                      label: 'Messenger',
                      value: 'Chat with us',
                      onTap: () => launchUrl(
                        Uri.parse(config.messengerLink),
                        mode: LaunchMode.externalApplication,
                      ),
                      iconColor: const Color(0xFF0084FF),
                      isFirst: config.contactPhone.isEmpty,
                      isLast: true,
                    ),
                ],
              ),
            ),
            const Gap(16),
          ],

          // ── Runner Program ────────────────────────────────────────────────
          if (!isApprovedRunner) ...[
            _SectionLabel('Runner Program'),
            const Gap(10),
            runnerAsync.when(
              loading: () => const SizedBox(
                height: 44,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (app) => _RunnerSection(app: app),
            ),
            const Gap(16),
          ],

          // ── Terms & Privacy ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => context.push('/terms'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ),
              const Text('·',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 12)),
              TextButton(
                onPressed: () => context.push('/privacy'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ),
            ],
          ),
          const Gap(4),

          // ── Sign Out ─────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          const Gap(8),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ── 区块标签 ──────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Runner 卡片按钮（用于渐变卡内）─────────────────────────────────────────────────

class _RunnerCardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _RunnerCardButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: filled
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: filled ? AppColors.primary : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phone + Address 合并卡片 ──────────────────────────────────────────────────────

class _CombinedInfoTile extends StatelessWidget {
  final String phone;
  final String address;
  final VoidCallback onEditAddress;

  const _CombinedInfoTile({
    required this.phone,
    required this.address,
    required this.onEditAddress,
  });

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: AppColors.onBackground),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (onTap != null)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4),
            child: Icon(Icons.edit_outlined,
                size: 14, color: AppColors.onSurfaceVariant),
          ),
      ],
    );
    return onTap != null
        ? GestureDetector(onTap: onTap, child: row)
        : row;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: phone,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _row(
            icon: Icons.location_on_outlined,
            label: 'Delivery Address',
            value: address,
            onTap: onEditAddress,
          ),
        ],
      ),
    );
  }
}

// ── Runner 申请区块 ───────────────────────────────────────────────────────────────

class _RunnerSection extends StatelessWidget {
  final RunnerApplicationModel app;
  const _RunnerSection({required this.app});

  @override
  Widget build(BuildContext context) {
    if (app.isNone) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delivery_dining,
                color: AppColors.primary, size: 22),
          ),
          title: const Text('Become a Runner',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: const Text('Earn money delivering orders',
              style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.onSurfaceVariant),
          onTap: () => context.push('/runner/apply'),
        ),
      );
    }
    if (app.isPending) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hourglass_top_outlined,
                  color: AppColors.info, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application Pending',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.info)),
                  Gap(2),
                  Text('We\'ll notify you once reviewed.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (app.isRejected) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Application Rejected',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.error)),
                      const Gap(2),
                      Text(
                        app.rejectReason ?? 'No reason given',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/runner/apply', extra: app),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reapply'),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ── 通用菜单 Tile ─────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.onSurfaceVariant, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── 联系方式 Tile ─────────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool isFirst;
  final bool isLast;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: iconColor ?? AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: iconColor ?? AppColors.primary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.onSurfaceVariant, size: 14),
          ],
        ),
      ),
    );
  }
}
