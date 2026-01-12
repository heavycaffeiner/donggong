import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/state/navigation_state.dart';
import '../presentation/state/recent_state.dart';
import '../models/types.dart' show CustomScreen;

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final navState = Provider.of<NavigationState>(context);
    final theme = Theme.of(context);

    int selectedIndex = 0;
    switch (navState.screen) {
      case CustomScreen.home:
        selectedIndex = 0;
        break;
      case CustomScreen.recentViewed:
        selectedIndex = 1;
        break;
      case CustomScreen.favorites:
        selectedIndex = 2;
        break;
      case CustomScreen.settings:
        selectedIndex = 3;
        break;
      default:
        selectedIndex = 0;
    }

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        CustomScreen screen = CustomScreen.home;
        switch (index) {
          case 0:
            screen = CustomScreen.home;
            break;
          case 1:
            screen = CustomScreen.recentViewed;
            Provider.of<RecentState>(context, listen: false).loadRecents();
            break;
          case 2:
            screen = CustomScreen.favorites;
            break;
          case 3:
            screen = CustomScreen.settings;
            break;
        }
        navState.setScreen(screen);
        Navigator.pop(context);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 16, 10),
          child: Text(
            'Donggong',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('Recent'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: Text('Favorites'),
        ),
        const Divider(indent: 28, endIndent: 28),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
