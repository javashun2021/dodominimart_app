import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/models/address_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';

class AddressListScreen extends ConsumerWidget {
  final bool selectable;
  const AddressListScreen({super.key, this.selectable = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectable ? 'Select Address' : 'My Addresses'),
      ),
      floatingActionButton: selectable
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final added = await context.push<bool>('/addresses/add');
                if (added == true) ref.invalidate(addressesProvider);
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: addressesAsync.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (e, _) => Center(
          child: Text('Failed to load addresses: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const Center(
              child: Text('No addresses yet',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, i) {
              final addr = addresses[i];
              return _AddressCard(
                address: addr,
                selectable: selectable,
                onSelect: selectable ? () => context.pop(addr.addressId) : null,
                onSetDefault: addr.isDefault
                    ? null
                    : () => _setDefault(context, ref, addr.addressId),
                onDelete: () => _confirmDelete(context, ref, addr.addressId),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _setDefault(
      BuildContext context, WidgetRef ref, int id) async {
    final client = ref.read(apiClientProvider);
    try {
      final res =
          await client.put(ApiEndpoints.addressDefault(id.toString()));
      if (res.data!['code'] != 0) throw Exception(res.data!['msg']);
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;

    final client = ref.read(apiClientProvider);
    try {
      final res =
          await client.delete(ApiEndpoints.memberAddress(id.toString()));
      if (res.data!['code'] != 0) throw Exception(res.data!['msg']);
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool selectable;
  final VoidCallback? onSelect;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const _AddressCard({
    required this.address,
    required this.selectable,
    this.onSelect,
    this.onSetDefault,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectable ? onSelect : null,
      onLongPress: selectable ? null : () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: address.isDefault ? AppColors.primary : AppColors.border,
            width: address.isDefault ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: address.isDefault
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              size: 22,
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
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryLight.withValues(alpha: 0.2),
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
            if (selectable)
              const Icon(Icons.chevron_right,
                  color: AppColors.onSurfaceVariant)
            else
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                color: AppColors.onSurfaceVariant,
                onPressed: () => _showOptions(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (onSetDefault != null)
              ListTile(
                leading:
                    const Icon(Icons.star_outline, color: AppColors.primary),
                title: const Text('Set as Default'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSetDefault!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
