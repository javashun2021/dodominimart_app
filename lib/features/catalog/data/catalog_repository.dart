import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

// ─── Interface ───────────────────────────────────────────────────────────────

abstract class ICatalogRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getProducts({String? categoryId, String? keyword});
  Future<ProductModel> getProduct(String id);
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final _mockCategories = [
  const CategoryModel(id: 'cat-1', name: 'Beverages', sortOrder: 1, isActive: true),
  const CategoryModel(id: 'cat-2', name: 'Snacks', sortOrder: 2, isActive: true),
  const CategoryModel(id: 'cat-3', name: 'Personal Care', sortOrder: 3, isActive: true),
  const CategoryModel(id: 'cat-4', name: 'Household', sortOrder: 4, isActive: true),
  const CategoryModel(id: 'cat-5', name: 'Instant Food', sortOrder: 5, isActive: true),
];

final _mockProducts = [
  // Beverages
  const ProductModel(id: 'p-01', name: 'Coca-Cola 1.5L', description: 'Refreshing cold Coca-Cola in a 1.5L bottle', categoryId: 'cat-1', categoryName: 'Beverages', price: 65, stock: 20, isAvailable: true, isFeatured: true, unit: 'bottle', tags: ['cold', 'soda', 'drinks']),
  const ProductModel(id: 'p-02', name: 'Royal Tru-Orange 1L', description: 'Classic orange-flavored soft drink', categoryId: 'cat-1', categoryName: 'Beverages', price: 50, stock: 15, isAvailable: true, isFeatured: false, unit: 'bottle', tags: ['soda', 'orange', 'drinks']),
  const ProductModel(id: 'p-03', name: 'Mineral Water 500ml', description: 'Purified drinking water', categoryId: 'cat-1', categoryName: 'Beverages', price: 15, stock: 50, isAvailable: true, isFeatured: false, unit: 'bottle', tags: ['water', 'drinks']),
  const ProductModel(id: 'p-04', name: 'Milo 3-in-1 Sachet', description: 'Chocolate malt energy drink mix', categoryId: 'cat-1', categoryName: 'Beverages', price: 12, stock: 100, isAvailable: true, isFeatured: true, unit: 'sachet', tags: ['chocolate', 'hot drink', 'energy']),
  const ProductModel(id: 'p-05', name: 'C2 Apple Green Tea 355ml', description: 'Refreshing apple green tea', categoryId: 'cat-1', categoryName: 'Beverages', price: 25, stock: 30, isAvailable: true, isFeatured: false, unit: 'bottle', tags: ['tea', 'cold', 'drinks']),
  // Snacks
  const ProductModel(id: 'p-06', name: 'Piattos Cheese 85g', description: 'Crunchy potato crisps with cheese flavor', categoryId: 'cat-2', categoryName: 'Snacks', price: 35, stock: 25, isAvailable: true, isFeatured: true, unit: 'pack', tags: ['chips', 'cheese', 'snacks']),
  const ProductModel(id: 'p-07', name: 'Chippy Barbecue 110g', description: 'Corn chips with barbecue flavor', categoryId: 'cat-2', categoryName: 'Snacks', price: 30, stock: 20, isAvailable: true, isFeatured: false, unit: 'pack', tags: ['chips', 'bbq', 'snacks']),
  const ProductModel(id: 'p-08', name: 'Choco Mallows 100g', description: 'Chocolate-coated marshmallow treats', categoryId: 'cat-2', categoryName: 'Snacks', price: 35, stock: 18, isAvailable: true, isFeatured: false, unit: 'pack', tags: ['chocolate', 'sweet', 'snacks']),
  const ProductModel(id: 'p-09', name: 'Skyflakes Crackers 33g', description: 'Crispy wheat crackers', categoryId: 'cat-2', categoryName: 'Snacks', price: 12, stock: 40, isAvailable: true, isFeatured: false, unit: 'pack', tags: ['crackers', 'biscuits', 'snacks']),
  // Personal Care
  const ProductModel(id: 'p-10', name: 'Safeguard White Soap 135g', description: 'Antibacterial bathing soap', categoryId: 'cat-3', categoryName: 'Personal Care', price: 55, stock: 15, isAvailable: true, isFeatured: false, unit: 'piece', tags: ['soap', 'hygiene', 'bath']),
  const ProductModel(id: 'p-11', name: 'Sunsilk Shampoo Sachet 6ml', description: 'Hair shampoo sachet for smooth hair', categoryId: 'cat-3', categoryName: 'Personal Care', price: 8, stock: 60, isAvailable: true, isFeatured: false, unit: 'sachet', tags: ['shampoo', 'hair', 'hygiene']),
  const ProductModel(id: 'p-12', name: 'Colgate Toothpaste 50ml', description: 'Fresh mint toothpaste', categoryId: 'cat-3', categoryName: 'Personal Care', price: 45, stock: 12, isAvailable: true, isFeatured: false, unit: 'tube', tags: ['toothpaste', 'dental', 'hygiene']),
  // Household
  const ProductModel(id: 'p-13', name: 'Joy Dishwashing Liquid 250ml', description: 'Lemon-scented dishwashing liquid', categoryId: 'cat-4', categoryName: 'Household', price: 45, stock: 10, isAvailable: true, isFeatured: false, unit: 'bottle', tags: ['cleaning', 'dishes', 'household']),
  const ProductModel(id: 'p-14', name: 'Ariel Detergent Powder 65g', description: 'Laundry detergent powder sachet', categoryId: 'cat-4', categoryName: 'Household', price: 14, stock: 50, isAvailable: true, isFeatured: false, unit: 'sachet', tags: ['laundry', 'cleaning', 'household']),
  // Instant Food
  const ProductModel(id: 'p-15', name: 'Lucky Me Pancit Canton', description: 'Original flavor instant noodles', categoryId: 'cat-5', categoryName: 'Instant Food', price: 16, stock: 40, isAvailable: true, isFeatured: true, unit: 'pack', tags: ['noodles', 'instant', 'food']),
  const ProductModel(id: 'p-16', name: 'Nissin Cup Noodles Seafood', description: 'Ready-to-eat cup noodles', categoryId: 'cat-5', categoryName: 'Instant Food', price: 28, stock: 20, isAvailable: true, isFeatured: false, unit: 'cup', tags: ['noodles', 'instant', 'food']),
  const ProductModel(id: 'p-17', name: 'Argentina Corned Beef 150g', description: 'Premium corned beef for any meal', categoryId: 'cat-5', categoryName: 'Instant Food', price: 55, stock: 15, isAvailable: true, isFeatured: false, unit: 'can', tags: ['corned beef', 'canned', 'food']),
  const ProductModel(id: 'p-18', name: 'Bear Brand Sterilized Milk 140ml', description: 'Full-cream sterilized milk', categoryId: 'cat-5', categoryName: 'Instant Food', price: 22, stock: 0, isAvailable: false, isFeatured: false, unit: 'can', tags: ['milk', 'drinks', 'food']),
];

// ─── Mock ─────────────────────────────────────────────────────────────────────

class MockCatalogRepository implements ICatalogRepository {
  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockCategories;
  }

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? keyword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var products = _mockProducts.where((p) => p.isAvailable || p.stock <= 0);
    if (categoryId != null && categoryId.isNotEmpty) {
      products = products.where((p) => p.categoryId == categoryId);
    }
    if (keyword != null && keyword.isNotEmpty) {
      final q = keyword.toLowerCase();
      products = products.where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            p.tags.any((t) => t.contains(q)),
      );
    }
    return products.toList();
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockProducts.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Product not found'),
    );
  }
}

// ─── Real API ─────────────────────────────────────────────────────────────────

class ApiCatalogRepository implements ICatalogRepository {
  final ApiClient _client;

  ApiCatalogRepository(this._client);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get(ApiEndpoints.categories);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final rawData = json['data'] ?? json['list'];
    final list = rawData as List<dynamic>? ?? [];
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? keyword,
  }) async {
    final response = await _client.get(ApiEndpoints.products, params: {
      if (categoryId != null) 'categoryId': categoryId,
      if (keyword != null) 'keyword': keyword,
      'pageNum': 1,
      'pageSize': 100,
    });
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    final list = json['list'] as List<dynamic>? ?? [];
    return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    final response = await _client.get(ApiEndpoints.productDetail(id));
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return ProductModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}
