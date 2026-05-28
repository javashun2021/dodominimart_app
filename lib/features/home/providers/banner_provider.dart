import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/banner_repository.dart';
import '../models/banner_model.dart';

final bannersProvider = FutureProvider<List<BannerModel>>((ref) {
  return ref.watch(bannerRepositoryProvider).getActiveBanners();
});
