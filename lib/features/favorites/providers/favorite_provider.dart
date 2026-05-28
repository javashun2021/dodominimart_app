import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/favorite_repository.dart';

class FavoriteIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    // Automatically re-runs when auth state changes (login / logout)
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) return {};
    final ids = await ref.read(favoriteRepositoryProvider).getFavoriteIds();
    return ids.toSet();
  }

  Future<void> toggle(String productId) async {
    final current = state.valueOrNull ?? {};
    final wasFavorited = current.contains(productId);

    // Optimistic update
    state = AsyncData(
      wasFavorited ? ({...current}..remove(productId)) : {...current, productId},
    );

    try {
      final repo = ref.read(favoriteRepositoryProvider);
      if (wasFavorited) {
        await repo.removeFavorite(productId);
      } else {
        await repo.addFavorite(productId);
      }
    } catch (_) {
      // Roll back on error
      state = AsyncData(current);
      rethrow;
    }
  }
}

final favoriteIdsProvider =
    AsyncNotifierProvider<FavoriteIdsNotifier, Set<String>>(
  FavoriteIdsNotifier.new,
);

/// Convenience selector — true if the given product is in the favorites set.
final isFavoritedProvider = Provider.family<bool, String>((ref, productId) {
  final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
  return ids.contains(productId);
});
