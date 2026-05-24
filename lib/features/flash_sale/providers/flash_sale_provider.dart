import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/flash_sale_repository.dart';
import '../models/flash_sale_model.dart';

final activeFlashSalesProvider = FutureProvider<List<FlashSaleModel>>((ref) {
  return ref.watch(flashSaleRepositoryProvider).getActiveFlashSales();
});
