import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../models/app_config_model.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Fetched once at startup; auto-refreshes when auth state changes.
final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get(ApiEndpoints.config);
    final json = response.data;
    if (json == null || json['code'] != 0) return AppConfigModel.fallback;
    return AppConfigModel.fromJson(json);
  } catch (_) {
    return AppConfigModel.fallback;
  }
});
