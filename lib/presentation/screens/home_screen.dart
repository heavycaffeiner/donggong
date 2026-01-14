import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/shared.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfNeeded(force: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadIfNeeded({bool force = false}) {
    final settings = ref.read(settingsProvider).value;
    final searchState = ref.read(searchProvider);
    ref
        .read(galleryProvider.notifier)
        .loadGalleries(
          reset: true,
          defaultLang: settings?.defaultLanguage ?? 'korean',
          query: searchState.query,
          force: force,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final settings = ref.read(settingsProvider).value;
      final searchState = ref.read(searchProvider);
      ref
          .read(galleryProvider.notifier)
          .loadGalleries(
            defaultLang: settings?.defaultLanguage ?? 'korean',
            query: searchState.query,
          );
    }

    if (_scrollController.offset >= 500) {
      if (!_showFloatingButton) setState(() => _showFloatingButton = true);
    } else {
      if (_showFloatingButton) setState(() => _showFloatingButton = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);
    final settings = ref.watch(settingsProvider).value;
    final searchState = ref.watch(searchProvider);

    // Listen for navigation changes
    ref.listen(navigationProvider, (prev, next) {
      if (next == CustomScreen.home && prev != CustomScreen.reader) {
        _loadIfNeeded();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: _showFloatingButton
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(allowDirectId: true),
            Expanded(
              child: GalleryListView(
                items: galleryState.galleries,
                isLoading: galleryState.loading,
                scrollController: _scrollController,
                onRefresh: () => ref
                    .read(galleryProvider.notifier)
                    .refresh(
                      settings?.defaultLanguage ?? 'korean',
                      query: searchState.query,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
