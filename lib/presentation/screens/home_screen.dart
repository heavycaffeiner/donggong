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
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPage(1, force: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadPage(int page, {bool force = false}) {
    final settings = ref.read(settingsProvider).value;
    final searchState = ref.read(searchProvider);
    final listingMode = settings?.listingMode ?? 'scroll';

    setState(() => _currentPage = page);

    if (listingMode == 'pagination') {
      ref
          .read(galleryProvider.notifier)
          .loadGalleriesPage(
            page: page,
            defaultLang: settings?.defaultLanguage ?? 'korean',
            query: searchState.query,
          );
    } else {
      ref
          .read(galleryProvider.notifier)
          .loadGalleries(
            reset: page == 1,
            defaultLang: settings?.defaultLanguage ?? 'korean',
            query: searchState.query,
            force: force,
          );
    }
  }

  void _onScroll() {
    final settings = ref.read(settingsProvider).value;
    final listingMode = settings?.listingMode ?? 'scroll';

    // 스크롤 모드에서만 무한 스크롤 로드
    if (listingMode != 'pagination') {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final searchState = ref.read(searchProvider);
        ref
            .read(galleryProvider.notifier)
            .loadGalleries(
              defaultLang: settings?.defaultLanguage ?? 'korean',
              query: searchState.query,
            );
      }
    }

    // FAB 표시 로직은 모든 모드에서 동작
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
    final galleryState = ref.watch(galleryProvider);
    final settings = ref.watch(settingsProvider).value;
    final searchState = ref.watch(searchProvider);
    final cardViewMode = settings?.cardViewMode ?? 'thumbnail';
    final listingMode = settings?.listingMode ?? 'scroll';

    ref.listen(navigationProvider, (prev, next) {
      if (next == CustomScreen.home && prev != CustomScreen.reader) {
        _loadPage(_currentPage);
      }
    });

    ref.listen(settingsProvider, (prev, next) {
      final prevMode = prev?.value?.listingMode;
      final nextMode = next.value?.listingMode;
      final prevLang = prev?.value?.defaultLanguage;
      final nextLang = next.value?.defaultLanguage;
      // 리스팅 모드 또는 언어 변경 시 첫 페이지로 리셋
      if ((prevMode != nextMode && nextMode != null) ||
          (prevLang != nextLang && nextLang != null)) {
        _loadPage(1, force: true);
      }
    });

    // 페이지네이션 모드에서 페이지 바 높이 (패딩 16 + 아이콘버튼 48)
    final paginationBarHeight = listingMode == 'pagination' ? 64.0 : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(allowDirectId: true),
            Expanded(
              child: Stack(
                children: [
                  GalleryListView(
                    items: galleryState.galleries,
                    isLoading: galleryState.loading,
                    totalCount: galleryState.totalCount,
                    currentApiPage: _currentPage,
                    onPageChange: (page) => _loadPage(page),
                    scrollController: _scrollController,
                    onRefresh: () async {
                      await ref
                          .read(galleryProvider.notifier)
                          .refresh(
                            settings?.defaultLanguage ?? 'korean',
                            query: searchState.query,
                          );
                      setState(() => _currentPage = 1);
                    },
                  ),
                  // FAB 버튼들 (페이지 바 위에 배치)
                  Positioned(
                    right: 16,
                    bottom: 16 + paginationBarHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'viewMode',
                          onPressed: _toggleCardViewMode,
                          child: Icon(
                            cardViewMode == 'thumbnail'
                                ? Icons.view_agenda
                                : Icons.view_day,
                          ),
                        ),
                        if (_showFloatingButton) ...[
                          const SizedBox(height: 12),
                          FloatingActionButton(
                            heroTag: 'scrollToTop',
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
}
