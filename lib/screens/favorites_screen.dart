import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/state/favorite_state.dart';
import '../presentation/state/search_state.dart';
import '../presentation/widgets/common/gallery_list_view.dart';
import '../presentation/widgets/common/search_bar_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favState = Provider.of<FavoriteState>(context, listen: false);
      final searchState = Provider.of<SearchState>(context, listen: false);
      favState.clear();
      favState.loadFavorites(query: searchState.query);
    });
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
              child: RefreshIndicator(
                onRefresh: favState.refreshFavorites,
                child: GalleryListView(
                  items: favState.favorites,
                  isLoading: favState.loading,
                  emptyMessage: 'No favorites found',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
