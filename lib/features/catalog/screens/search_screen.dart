import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) {
            Future.delayed(const Duration(milliseconds: 350), () {
              if (v == _ctrl.text) {
                ref.read(searchQueryProvider.notifier).state = v;
              }
            });
          },
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.search,
              title: 'Search for products',
              subtitle: 'Type a product name to find what you need.',
            )
          : resultsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No results for "$query"',
                    subtitle: 'Try a different keyword.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) =>
                      ProductCard(product: products[i]),
                );
              },
            ),
    );
  }
}
