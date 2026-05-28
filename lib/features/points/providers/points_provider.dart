import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/points_repository.dart';
import '../models/points_model.dart';

final pointsProvider = FutureProvider<PointsModel>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return const PointsModel(balance: 0, logs: []);
  }
  return ref.watch(pointsRepositoryProvider).getPoints();
});
