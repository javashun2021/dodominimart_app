import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_config_model.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

// ─── Search history provider (SharedPreferences) ──────────────────────────────

final _historyKey = 'search_history';
const _maxHistory = 10;

final searchHistoryProvider =
    StateNotifierProvider<_HistoryNotifier, List<String>>((ref) {
  return _HistoryNotifier(ref.watch(sharedPreferencesProvider));
});

class _HistoryNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;

  _HistoryNotifier(this._prefs)
      : super(_prefs.getStringList(_historyKey) ?? []);

  void add(String term) {
    if (term.trim().isEmpty) return;
    final updated = [
      term.trim(),
      ...state.where((h) => h != term.trim()),
    ].take(_maxHistory).toList();
    state = updated;
    _prefs.setStringList(_historyKey, updated);
  }

  void remove(String term) {
    final updated = state.where((h) => h != term).toList();
    state = updated;
    _prefs.setStringList(_historyKey, updated);
  }

  void clear() {
    state = [];
    _prefs.remove(_historyKey);
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

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

  void _search(String term) {
    if (term.trim().isEmpty) return;
    _ctrl.text = term;
    ref.read(searchQueryProvider.notifier).state = term.trim();
    ref.read(searchHistoryProvider.notifier).add(term.trim());
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider(query));
    final history = ref.watch(searchHistoryProvider);
    final config = ref.watch(appConfigProvider).valueOrNull ??
        AppConfigModel.fallback;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
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
          onSubmitted: _search,
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
          ? _EmptyQueryBody(
              history: history,
              hotwords: config.searchHotwords,
              onTap: _search,
              onRemoveHistory: (h) =>
                  ref.read(searchHistoryProvider.notifier).remove(h),
              onClearHistory: () =>
                  ref.read(searchHistoryProvider.notifier).clear(),
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

class _EmptyQueryBody extends StatelessWidget {
  final List<String> history;
  final List<String> hotwords;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemoveHistory;
  final VoidCallback onClearHistory;

  const _EmptyQueryBody({
    required this.history,
    required this.hotwords,
    required this.onTap,
    required this.onRemoveHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty && hotwords.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search,
        title: 'Search for products',
        subtitle: 'Type a product name to find what you need.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hotwords.isNotEmpty) ...[
          const Text('Popular',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.onBackground)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hotwords
                .map((w) => ActionChip(
                      label: Text(w),
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.12),
                      labelStyle: const TextStyle(
                          color: AppColors.primary, fontSize: 13),
                      side: BorderSide.none,
                      onPressed: () => onTap(w),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.onBackground)),
              TextButton(
                onPressed: onClearHistory,
                child: const Text('Clear',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
              ),
            ],
          ),
          ...history.map((h) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history,
                    color: AppColors.onSurfaceVariant, size: 20),
                title: Text(h, style: const TextStyle(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.onSurfaceVariant),
                  onPressed: () => onRemoveHistory(h),
                ),
                onTap: () => onTap(h),
              )),
        ],
      ],
    );
  }
}
