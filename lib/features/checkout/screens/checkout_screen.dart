import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_config_model.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/models/address_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../providers/checkout_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  int? _selectedAddressId;
  String _paymentMethod = 'COD'; // "COD" | "GCASH"

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(double deliveryFee) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }
    await ref.read(checkoutProvider.notifier).placeOrder(
          addressId: _selectedAddressId!,
          remark: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          paymentMethod: _paymentMethod,
        );
    if (!mounted) return;
    final state = ref.read(checkoutProvider);
    if (state.status == CheckoutStatus.success && state.placedOrder != null) {
      if (_paymentMethod == 'GCASH' && state.gcashInfo != null) {
        context.go(
          '/payment/gcash/${state.placedOrder!.id}',
          extra: state.gcashInfo,
        );
      } else {
        context.go('/order-success/${state.placedOrder!.id}');
      }
    } else if (state.status == CheckoutStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to place order'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final isLoading = checkoutState.status == CheckoutStatus.loading;
    final configAsync = ref.watch(appConfigProvider);
    final addressesAsync = ref.watch(addressesProvider);

    final deliveryFee = configAsync.valueOrNull?.deliveryFee ??
        AppConfigModel.fallback.deliveryFee;
    final total = cart.subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('Delivery Address'),
            const Gap(12),
            addressesAsync.when(
              loading: () => const SizedBox(
                  height: 80, child: Center(child: LoadingWidget())),
              error: (e, _) => Text('Failed to load addresses: $e',
                  style: const TextStyle(color: AppColors.error)),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return _NoAddressCard(
                      onTap: () => context.push('/onboarding'));
                }
                if (_selectedAddressId == null) {
                  final def =
                      addresses.where((a) => a.isDefault).firstOrNull;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() =>
                        _selectedAddressId = (def ?? addresses.first).addressId);
                  });
                }
                return Column(
                  children: addresses
                      .map((addr) => _AddressTile(
                            address: addr,
                            selected: _selectedAddressId == addr.addressId,
                            onTap: () => setState(
                                () => _selectedAddressId = addr.addressId),
                          ))
                      .toList(),
                );
              },
            ),
            const Gap(16),
            _SectionTitle('Delivery Notes'),
            const Gap(12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Leave at gate',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const Gap(20),
            _SectionTitle('Order Summary'),
            const Gap(12),
            ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} × ${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '₱${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            const Gap(4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₱${cart.subtotal.toStringAsFixed(0)}'),
              ],
            ),
            const Gap(6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery fee'),
                Text('₱${deliveryFee.toStringAsFixed(0)}'),
              ],
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '₱${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Gap(20),
            _SectionTitle('Payment Method'),
            const Gap(12),
            _PaymentMethodCard(
              method: 'COD',
              selected: _paymentMethod == 'COD',
              onTap: () => setState(() => _paymentMethod = 'COD'),
            ),
            if (configAsync.valueOrNull?.gcashEnabled == true) ...[
              const Gap(8),
              _PaymentMethodCard(
                method: 'GCASH',
                selected: _paymentMethod == 'GCASH',
                onTap: () => setState(() => _paymentMethod = 'GCASH'),
              ),
            ],
            if (configAsync.valueOrNull?.hasMessenger == true) ...[
              const Gap(8),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(configAsync.value!.messengerLink),
                  mode: LaunchMode.externalApplication,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0084FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            const Color(0xFF0084FF).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF0084FF), size: 20),
                      SizedBox(width: 10),
                      Text('Chat us on Messenger',
                          style: TextStyle(
                              color: Color(0xFF0084FF),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
            const Gap(24),
            ElevatedButton(
              onPressed: isLoading ? null : () => _placeOrder(deliveryFee),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_paymentMethod == 'GCASH'
                      ? 'Pay via GCash · ₱${total.toStringAsFixed(0)}'
                      : 'Place Order · ₱${total.toStringAsFixed(0)}'),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.border,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Default',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryDark)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(address.fullAddress,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant)),
                  if (address.phone?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(address.phone!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAddressCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoAddressCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.border)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_location_outlined, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Add a delivery address',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground));
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String method; // "COD" | "GCASH"
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCod = method == 'COD';
    final color = isCod ? AppColors.success : const Color(0xFF007AFF);
    final label = isCod ? 'Cash on Delivery' : 'GCash';
    final subtitle =
        isCod ? 'Pay when your order arrives' : 'Pay online via GCash';
    final icon = isCod ? Icons.payments_outlined : Icons.account_balance_wallet_outlined;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : AppColors.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? color : AppColors.onBackground)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? color : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
