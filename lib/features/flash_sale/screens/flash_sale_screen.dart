import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/countdown_timer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../models/flash_sale_model.dart';
import '../providers/flash_sale_provider.dart';

class FlashSaleScreen extends ConsumerWidget {
  const FlashSaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(activeFlashSalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Sale 🔥',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: salesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 60, color: AppColors.border),
                  Gap(12),
                  Text('No active flash sales',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (_, i) => _FlashSaleCard(sale: sales[i]),
          );
        },
      ),
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  final FlashSaleModel sale;
  const _FlashSaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products/${sale.productId}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: 100,
                child: sale.resolvedProductImage != null
                    ? Image.network(sale.resolvedProductImage!,
                        fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.border)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.onBackground),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Gap(6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${sale.flashPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₱${sale.originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 13, color: AppColors.error),
                        const SizedBox(width: 4),
                        CountdownTimer(endTime: sale.endTime, showLabel: true),
                        const Spacer(),
                        Text('${sale.stockLeft} left',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const Gap(4),
                    // Stock progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: sale.stockLimit > 0
                            ? sale.soldCount / sale.stockLimit
                            : 0,
                        backgroundColor:
                            AppColors.error.withValues(alpha: 0.12),
                        color: AppColors.error,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}
