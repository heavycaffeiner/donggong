import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/shared.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfNeeded();
    });
  }

  void _loadIfNeeded() {
    // 캐시 무시하고 항상 새로고침
    final query = ref.read(searchProvider).query;
    ref.read(favoriteProvider.notifier).refreshFavorites(query: query);
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(favoriteProvider);

    ref.listen(navigationProvider, (prev, next) {
      if (next == CustomScreen.favorites) {
        _loadIfNeeded();
      }
    });

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
