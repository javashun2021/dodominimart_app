import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/catalog_repository.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

// ─── Switch between mock and real API ────────────────────────────────────────
const _useMock = false;

final catalogRepositoryProvider = Provider<ICatalogRepository>((ref) {
  if (_useMock) return MockCatalogRepository();
  return ApiCatalogRepository(ref.watch(apiClientProvider));
});

// ─── Selected category filter ─────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ─── Categories ───────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(catalogRepositoryProvider).getCategories();
});

// ─── Products (filtered) ──────────────────────────────────────────────────────

final productsProvider =
    FutureProvider.family<List<ProductModel>, String?>((ref, categoryId) {
  return ref.watch(catalogRepositoryProvider).getProducts(categoryId: categoryId);
});

// ─── Single product ───────────────────────────────────────────────────────────

final productDetailProvider =
    FutureProvider.family<ProductModel, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).getProduct(id);
});

// ─── Search ───────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return ref
      .watch(catalogRepositoryProvider)
      .getProducts(keyword: query.trim());
});
