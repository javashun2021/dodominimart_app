import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../orders/models/gcash_payment_info.dart';
import '../../orders/providers/orders_provider.dart';

class GCashPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  final GCashPaymentInfo? gcashInfo;

  const GCashPaymentScreen({
    super.key,
    required this.orderId,
    this.gcashInfo,
  });

  @override
  ConsumerState<GCashPaymentScreen> createState() => _GCashPaymentScreenState();
}

class _GCashPaymentScreenState extends ConsumerState<GCashPaymentScreen> {
  Timer? _pollTimer;
  bool _isExpired = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final order = await ref
            .read(orderRepositoryProvider)
            .getOrder(widget.orderId);
        if (!mounted) return;

        final status = order.paymentStatus.toUpperCase();
        if (status == 'PAID') {
          _pollTimer?.cancel();
          context.go('/order-success/${widget.orderId}');
        } else if (status == 'FAILED') {
          _pollTimer?.cancel();
          setState(() => _isFailed = true);
        } else if (status == 'EXPIRED') {
          _pollTimer?.cancel();
          setState(() => _isExpired = true);
        }
      } catch (_) {
        // network error — keep polling
      }
    });
  }

  Future<void> _openPayUrl() async {
    final url = widget.gcashInfo?.payUrl ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.gcashInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GCash Payment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isExpired
              ? _StatusMessage(
                  icon: Icons.timer_off_outlined,
                  color: AppColors.warning,
                  title: 'Payment Expired',
                  message: 'This payment link has expired. Please place a new order.',
                  buttonLabel: 'Back to Orders',
                  onButton: () => context.go('/orders'),
                )
              : _isFailed
                  ? _StatusMessage(
                      icon: Icons.error_outline,
                      color: AppColors.error,
                      title: 'Payment Failed',
                      message: 'Your GCash payment could not be processed.',
                      buttonLabel: 'Back to Orders',
                      onButton: () => context.go('/orders'),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _GCashHeader(),
                        const Gap(24),
                        if (info?.resolvedQrCodeUrl != null) ...[
                          Center(
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: info!.resolvedQrCodeUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.qr_code_2,
                                    size: 80,
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(16),
                        ],
                        if (info != null) ...[
                          Center(
                            child: Text(
                              '₱${info.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                          const Gap(4),
                          Center(
                            child: Text(
                              'Ref: ${info.referenceNo}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                        const Gap(24),
                        ElevatedButton.icon(
                          onPressed: _openPayUrl,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open GCash App'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const Gap(12),
                        const _PollingIndicator(),
                        const Gap(16),
                        TextButton(
                          onPressed: () => context.go('/orders'),
                          child: const Text('Check Later in My Orders'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _GCashHeader extends StatelessWidget {
  const _GCashHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: Color(0xFF007AFF), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complete your GCash payment',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF))),
                Text('Scan the QR or tap "Open GCash App"',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PollingIndicator extends StatelessWidget {
  const _PollingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          'Waiting for payment confirmation...',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onButton;

  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: color),
        const Gap(16),
        Text(title,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const Gap(8),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurfaceVariant)),
        const Gap(24),
        ElevatedButton(onPressed: onButton, child: Text(buttonLabel)),
      ],
    );
  }
}
