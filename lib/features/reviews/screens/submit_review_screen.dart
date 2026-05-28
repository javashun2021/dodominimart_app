import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../orders/models/order_model.dart';
import '../../orders/models/order_item_model.dart';
import '../data/review_repository.dart';
import '../providers/review_provider.dart';

class SubmitReviewScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const SubmitReviewScreen({super.key, required this.order});

  @override
  ConsumerState<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends ConsumerState<SubmitReviewScreen> {
  // productId → score (1–5)
  final Map<String, int> _scores = {};
  // productId → content
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      _scores[item.productId] = 5;
      _controllers[item.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(List<String> alreadyReviewedIds) async {
    final pending = widget.order.items
        .where((item) => !alreadyReviewedIds.contains(item.productId))
        .toList();

    if (pending.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All items already reviewed')),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final reviews = pending.map((item) => {
            'productId': int.parse(item.productId),
            'score': _scores[item.productId] ?? 5,
            'content': _controllers[item.productId]?.text.trim(),
          }).toList();

      await ref
          .read(reviewRepositoryProvider)
          .submitReviews(widget.order.id, reviews);

      ref.invalidate(reviewedProductIdsProvider(widget.order.id));
      ref.invalidate(productReviewsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your review!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewedAsync =
        ref.watch(reviewedProductIdsProvider(widget.order.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Write a Review',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        surfaceTintColor: Colors.transparent,
      ),
      body: reviewedAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alreadyReviewedIds) {
          final pending = widget.order.items
              .where((item) => !alreadyReviewedIds.contains(item.productId))
              .toList();

          if (pending.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.success),
                  Gap(16),
                  Text('All items reviewed!',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (_, i) =>
                      _ReviewCard(
                        item: pending[i],
                        score: _scores[pending[i].productId] ?? 5,
                        controller:
                            _controllers[pending[i].productId]!,
                        onScoreChanged: (s) => setState(
                            () => _scores[pending[i].productId] = s),
                      ),
                ),
              ),
              _SubmitBar(
                submitting: _submitting,
                onTap: () => _submit(alreadyReviewedIds),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 单个商品评价卡片 ────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final OrderItemModel item;
  final int score;
  final TextEditingController controller;
  final ValueChanged<int> onScoreChanged;

  const _ReviewCard({
    required this.item,
    required this.score,
    required this.controller,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    final imgUrl = ApiEndpoints.resolveImage(item.productImageUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imgUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(14),

          // Star rating
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => onScoreChanged(star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    star <= score ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: star <= score ? const Color(0xFFFFC107) : AppColors.border,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const Gap(12),

          // Text input
          TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)…',
              hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 52,
        height: 52,
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.image_outlined,
            color: AppColors.border, size: 24),
      );
}

// ── 提交按钮栏 ─────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final bool submitting;
  final VoidCallback onTap;

  const _SubmitBar({required this.submitting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: submitting ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Submit Review',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
