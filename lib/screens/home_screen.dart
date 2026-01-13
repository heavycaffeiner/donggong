import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/gallery_state.dart';
import '../state/settings_state.dart';
import '../state/search_state.dart';
import '../state/navigation_state.dart';
import '../widgets/common/gallery_list_view.dart';
import '../widgets/common/search_bar_widget.dart';
import '../models/types.dart' show CustomScreen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  late NavigationState _navState;
  late SearchState _searchState;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _navState = Provider.of<NavigationState>(context, listen: false);
    _searchState = Provider.of<SearchState>(context, listen: false);
    _navState.addListener(_onNavigationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfNeeded(force: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _navState.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    // Load when switching to home tab
    if (_navState.screen == CustomScreen.home &&
        _navState.previousScreen != CustomScreen.reader) {
      _loadIfNeeded();
    }
  }

  void _loadIfNeeded({bool force = false}) {
    final galleryState = Provider.of<GalleryState>(context, listen: false);
    final settingsState = Provider.of<SettingsState>(context, listen: false);
    galleryState.loadGalleries(
      reset: true,
      defaultLang: settingsState.settings.defaultLanguage,
      query: _searchState.query,
      force: force,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final galleryState = Provider.of<GalleryState>(context, listen: false);
      final settingsState = Provider.of<SettingsState>(context, listen: false);
      galleryState.loadGalleries(
        defaultLang: settingsState.settings.defaultLanguage,
        query: _searchState.query,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = Provider.of<GalleryState>(context);
    final settingsState = Provider.of<SettingsState>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(allowDirectId: true),
            Expanded(
              child: GalleryListView(
                items: galleryState.galleries,
                isLoading: galleryState.loading,
                scrollController: _scrollController,
                onRefresh: () => galleryState.refresh(
                  settingsState.settings.defaultLanguage,
                  query: _searchState.query,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
