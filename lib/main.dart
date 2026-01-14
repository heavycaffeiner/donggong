import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/data.dart';
import 'domain/domain.dart';
import 'shared/shared.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/screens.dart';
import 'presentation/widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.init();
  runApp(const ProviderScope(child: DonggongApp()));
}

class DonggongApp extends ConsumerWidget {
  const DonggongApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value ?? SettingsData.defaults();

    final isOled = settings.theme == 'oledDark';
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

class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  static const _screens = [
    HomeScreen(),
    RecentScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(navigationProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    final title = screen.title.isEmpty ? '홈' : screen.title;
    final stackIndex = screen.stackIndex;

    return PopScope(
      canPop: screen != CustomScreen.reader,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && screen == CustomScreen.reader) {
          navNotifier.closeReader();
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
          if (screen == CustomScreen.reader) const ReaderScreen(),
        ],
      ),
    );
  }
}
