import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:donggong/shared/shared.dart';
import 'package:donggong/presentation/providers/providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(navigationProvider);
    final theme = Theme.of(context);

    final selectedIndex = screen.tabIndex < 0 ? 0 : screen.tabIndex;

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        final screens = [
          CustomScreen.home,
          CustomScreen.recentViewed,
          CustomScreen.favorites,
          CustomScreen.settings,
        ];
        if (index >= 0 && index < screens.length) {
          final screen = screens[index];
          if (screen == CustomScreen.recentViewed) {
            ref.read(recentProvider.notifier).loadRecents();
          }
          ref.read(navigationProvider.notifier).setScreen(screen);
        }
        Navigator.pop(context);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DongGong',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '— A Modern Hitomi Reader',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('홈'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('최근 본 작품'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: Text('즐겨찾기'),
        ),
        const Divider(indent: 28, endIndent: 28),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('설정'),
        ),
      ],
    );
  }
}
