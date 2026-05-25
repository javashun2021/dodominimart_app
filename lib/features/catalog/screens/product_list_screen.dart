import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../models/category_model.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCatId = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider(selectedCatId));
    final cartCount = ref.watch(cartProvider).totalQuantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () => context.push('/search'),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => _CategoryChips(
              categories: cats,
              selectedId: selectedCatId,
              onSelected: (id) => ref
                  .read(selectedCategoryProvider.notifier)
                  .state = id,
            ),
          ),
          const Divider(height: 1),
          // Products grid
          Expanded(
            child: productsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                child: Text('Error: $e'),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    subtitle: 'Try a different category.',
                  );
                }
                final desktop = isDesktop(context);
                final columns = desktop ? 4 : 2;
                final padding = desktop ? 20.0 : 12.0;
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(productsProvider(selectedCatId)),
                  child: centeredContent(
                    child: GridView.builder(
                      padding: EdgeInsets.all(padding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: padding,
                        crossAxisSpacing: padding,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) =>
                          ProductCard(product: products[i], animationIndex: i),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final void Function(String?) onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Chip(
            label: 'All',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          const Gap(8),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: cat.name,
                  selected: selectedId == cat.id,
                  onTap: () => onSelected(cat.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
