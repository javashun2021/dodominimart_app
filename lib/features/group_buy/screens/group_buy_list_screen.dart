import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/countdown_timer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../models/group_activity_model.dart';
import '../providers/group_buy_provider.dart';

class GroupBuyListScreen extends ConsumerWidget {
  const GroupBuyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activeGroupActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Buys',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: activitiesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 60, color: AppColors.border),
                  Gap(12),
                  Text('No active group buy activities',
                      style:
                          TextStyle(color: AppColors.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (_, i) =>
                _GroupActivityCard(activity: activities[i]),
          );
        },
      ),
    );
  }
}

class _GroupActivityCard extends StatelessWidget {
  final GroupActivityModel activity;
  const _GroupActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/group-activity/${activity.activityId}',
        extra: activity,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品图片
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: activity.resolvedProductImage != null
                      ? CachedNetworkImage(
                          imageUrl: activity.resolvedProductImage!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.info),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(activity.productName,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const Gap(6),
                    if (activity.tiers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: activity.tiers.map((tier) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${tier.label}: ₱${tier.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            '₱${activity.lowestPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info),
                          ),
                          if (activity.originalPrice != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₱${activity.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12,
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
                    const Gap(6),
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 13,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Min ${activity.minGroupSize} pax',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.timer_outlined,
                            size: 13,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        CountdownTimer(
                          endTime: activity.endTime,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.border, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.image_outlined,
            color: AppColors.border, size: 32),
      );
}
