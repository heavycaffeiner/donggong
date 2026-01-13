import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/db_service.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/recent_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reader_screen.dart';

import 'presentation/state/navigation_state.dart';
import 'presentation/state/gallery_state.dart';
import 'presentation/state/favorite_state.dart';
import 'presentation/state/reader_state.dart';
import 'presentation/state/settings_state.dart';
import 'presentation/state/search_state.dart';
import 'presentation/state/recent_state.dart';
import 'presentation/widgets/navigation/app_drawer.dart';
import 'models/types.dart' show CustomScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService.init();
  runApp(const AppBootstrapper());
}

class AppBootstrapper extends StatelessWidget {
  const AppBootstrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => NavigationState()),
        ChangeNotifierProvider(create: (_) => SearchState()),
        ChangeNotifierProvider(create: (_) => GalleryState()),
        ChangeNotifierProvider(create: (_) => FavoriteState()),
        ChangeNotifierProvider(create: (_) => ReaderState()),
        ChangeNotifierProvider(create: (_) => RecentState()),
      ],
      child: const DonggongApp(),
    );
  }
}

class DonggongApp extends StatelessWidget {
  const DonggongApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = Provider.of<SettingsState>(context);

    final isOled = settingsState.settings.theme == 'oledDark';
    const seedColor = Colors.indigo;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
        ).copyWith(
          surface: isOled ? Colors.black : null,
          onSurface: isOled ? Colors.white : null,
          surfaceContainer: isOled ? const Color(0xFF161616) : null,
        );

    return MaterialApp(
      title: 'Donggong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: isOled ? Colors.black : colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: isOled ? Colors.black : colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: colorScheme.surfaceContainer,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: const MainWrapper(),
    );
  }
}

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  static const _screens = [
    HomeScreen(),
    RecentScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navState = Provider.of<NavigationState>(context);

    // CustomScreen enum의 title/stackIndex 활용 (switch 문 제거)
    final title = navState.screen.title.isEmpty ? '홈' : navState.screen.title;
    final stackIndex = navState.screen.stackIndex;

    return PopScope(
      canPop: navState.screen != CustomScreen.reader,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navState.screen == CustomScreen.reader) {
          navState.closeReader();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            drawer: const AppDrawer(),
            body: IndexedStack(index: stackIndex, children: _screens),
          ),
          if (navState.screen == CustomScreen.reader) const ReaderScreen(),
        ],
      ),
    );
  }
}
