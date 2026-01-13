import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/favorite_state.dart';
import '../state/search_state.dart';
import '../state/navigation_state.dart';
import '../widgets/common/gallery_list_view.dart';
import '../widgets/common/search_bar_widget.dart';
import '../models/types.dart' show CustomScreen;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late SearchState _searchState;
  late NavigationState _navState;

  @override
  void initState() {
    super.initState();
    _searchState = Provider.of<SearchState>(context, listen: false);
    _navState = Provider.of<NavigationState>(context, listen: false);
    _navState.addListener(_onNavigationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _navState.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    // Load when switching to favorites tab
    if (_navState.screen == CustomScreen.favorites &&
        _navState.previousScreen != CustomScreen.reader) {
      _loadIfNeeded();
    }
  }

  void _loadIfNeeded() {
    final favState = Provider.of<FavoriteState>(context, listen: false);
    favState.loadFavorites(query: _searchState.query);
  }

  @override
  Widget build(BuildContext context) {
    final favState = Provider.of<FavoriteState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(),
            Expanded(
              child: GalleryListView(
                items: favState.favorites,
                isLoading: favState.loading,
                emptyMessage: 'No favorites found',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
