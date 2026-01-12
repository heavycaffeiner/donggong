import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/state/gallery_state.dart';
import '../presentation/state/settings_state.dart';
import '../presentation/state/search_state.dart';
import '../presentation/widgets/common/gallery_list_view.dart';
import '../presentation/widgets/common/search_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final galleryState = Provider.of<GalleryState>(context, listen: false);
      final settingsState = Provider.of<SettingsState>(context, listen: false);
      final searchState = Provider.of<SearchState>(context, listen: false);
      galleryState.clear();
      galleryState.loadGalleries(
        reset: true,
        defaultLang: settingsState.settings.defaultLanguage,
        query: searchState.query,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final galleryState = Provider.of<GalleryState>(context, listen: false);
      final settingsState = Provider.of<SettingsState>(context, listen: false);
      final searchState = Provider.of<SearchState>(context, listen: false);
      galleryState.loadGalleries(
        defaultLang: settingsState.settings.defaultLanguage,
        query: searchState.query,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = Provider.of<GalleryState>(context);
    final settingsState = Provider.of<SettingsState>(context, listen: false);
    final searchState = Provider.of<SearchState>(context, listen: false);

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

