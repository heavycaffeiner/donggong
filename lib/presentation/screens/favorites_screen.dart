import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/shared.dart';
import '../../core/app_config.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFavorites() {
    final query = ref.read(searchProvider).query;
    ref.read(favoriteProvider.notifier).refreshFavorites(query: query);
  }

  void _onScroll() {
    if (_scrollController.offset >= 500) {
      if (!_showFloatingButton) setState(() => _showFloatingButton = true);
    } else {
      if (_showFloatingButton) setState(() => _showFloatingButton = false);
    }
  }

  void _toggleCardViewMode() {
    final settings = ref.read(settingsProvider).value;
    final currentMode = settings?.cardViewMode ?? 'thumbnail';
    final newMode = currentMode == 'thumbnail' ? 'detailed' : 'thumbnail';
    ref.read(settingsProvider.notifier).setSetting('cardViewMode', newMode);
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(favoriteProvider);
    final settings = ref.watch(settingsProvider).value;
    final cardViewMode = settings?.cardViewMode ?? 'thumbnail';
    final listingMode = settings?.listingMode ?? 'scroll';

    ref.listen(navigationProvider, (prev, next) {
      if (next == CustomScreen.favorites) {
        _loadFavorites();
      }
    });

    // 페이지네이션 모드에서 페이지 바 높이
    final paginationBarHeight = listingMode == 'pagination' ? 64.0 : 0.0;

    // 페이지네이션용 데이터
    final itemsPerPage = AppConfig.itemsPerPage;
    final totalItems = favState.favorites.length;
    final totalPages = totalItems > 0 ? (totalItems / itemsPerPage).ceil() : 1;

    // 현재 페이지 아이템
    List<dynamic> displayItems;
    if (listingMode == 'pagination') {
      final start = (_currentPage - 1) * itemsPerPage;
      final end = (start + itemsPerPage).clamp(0, totalItems);
      displayItems = start < totalItems
          ? favState.favorites.sublist(start, end)
          : [];
    } else {
      displayItems = favState.favorites;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(),
            Expanded(
              child: Stack(
                children: [
                  // 페이지네이션 모드에서는 로컬 페이지네이션 사용
                  if (listingMode == 'pagination')
                    _buildPaginatedList(
                      context,
                      displayItems.cast(),
                      favState.loading,
                      totalPages,
                    )
                  else
                    GalleryListView(
                      items: favState.favorites,
                      isLoading: favState.loading,
                      emptyMessage: 'No favorites found',
                      scrollController: _scrollController,
                    ),
                  // FAB 버튼들
                  Positioned(
                    right: 16,
                    bottom: 16 + paginationBarHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'favViewMode',
                          onPressed: _toggleCardViewMode,
                          child: Icon(
                            cardViewMode == 'thumbnail'
                                ? Icons.view_agenda
                                : Icons.view_day,
                          ),
                        ),
                        if (_showFloatingButton ||
                            listingMode == 'pagination') ...[
                          const SizedBox(height: 12),
                          FloatingActionButton(
                            heroTag: 'favScrollToTop',
                            onPressed: () {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Icon(Icons.arrow_upward),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginatedList(
    BuildContext context,
    List<dynamic> items,
    bool isLoading,
    int totalPages,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 아이템 리스트
        Expanded(
          child: isLoading
              ? const LoadingWidget()
              : items.isEmpty
              ? Center(
                  child: Text(
                    'No favorites found',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GalleryCard(
                      item: item,
                      onTap: () {
                        ref.read(readerProvider.notifier).loadGallery(item.id);
                        ref
                            .read(navigationProvider.notifier)
                            .setScreen(CustomScreen.reader);
                      },
                      onLongPress: () {},
                    );
                  },
                ),
        ),
        // 페이지 네비게이션 바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1 && !isLoading
                    ? () => setState(() => _currentPage = 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 && !isLoading
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $totalPages',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages && !isLoading
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages && !isLoading
                    ? () => setState(() => _currentPage = totalPages)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
