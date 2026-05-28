import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../catalog/models/product_model.dart';
import '../../catalog/widgets/product_card.dart';
import '../data/favorite_repository.dart';
import '../providers/favorite_provider.dart';

final _favoritesListProvider = FutureProvider<List<ProductModel>>((ref) {
  // Re-fetch whenever the favorited-ids set changes
  ref.watch(favoriteIdsProvider);
  return ref.read(favoriteRepositoryProvider).getFavorites();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(_favoritesListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('My Favourites',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        surfaceTintColor: Colors.transparent,
      ),
      body: favAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(_favoritesListProvider.future),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, i) => ProductCard(
                product: products[i],
                animationIndex: i,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 72, color: AppColors.primary.withValues(alpha: 0.3)),
          const Gap(16),
          const Text(
            'No favourites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const Gap(8),
          const Text(
            'Tap the ♡ on any product to save it here',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
