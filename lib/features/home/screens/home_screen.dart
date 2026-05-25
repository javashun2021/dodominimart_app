import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/dodo_logo.dart';

class HomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({super.key, required this.navigationShell});

  static const _labels = ['Home', 'Products', 'Orders', 'Profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.store_outlined,
    Icons.receipt_long_outlined,
    Icons.person_outline_rounded,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.store_rounded,
    Icons.receipt_long_rounded,
    Icons.person_rounded,
  ];

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return _DesktopShell(
        navigationShell: navigationShell,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        labels: _labels,
        icons: _icons,
        selectedIcons: _selectedIcons,
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: List.generate(
          _labels.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_selectedIcons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final int currentIndex;
  final void Function(int) onTap;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;

  const _DesktopShell({
    required this.navigationShell,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          // ── 左侧导航栏 ──────────────────────────────────────────────
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo 区域
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: DodoLogoBar(),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // 导航项
                ...List.generate(labels.length, (i) {
                  final selected = currentIndex == i;
                  return _NavItem(
                    icon: Icon(selected ? selectedIcons[i] : icons[i]),
                    label: labels[i],
                    selected: selected,
                    onTap: () => onTap(i),
                  );
                }),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'DODO MiniMart',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── 主内容区 ────────────────────────────────────────────────
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF97316);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(
                color: selected ? primary : const Color(0xFF888888),
                size: 22,
              ),
              child: icon,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? primary : const Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
