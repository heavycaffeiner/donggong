import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:donggong/data/data.dart';
import 'package:donggong/shared/shared.dart';
import 'package:donggong/core/app_config.dart';
import 'package:donggong/presentation/providers/providers.dart';
import 'package:donggong/presentation/widgets/detail/detail_bottom_sheet.dart';
import 'gallery_card.dart';
import 'loading_widget.dart';

/// 공통 갤러리 리스트 위젯
class GalleryListView extends ConsumerWidget {
  final List<GalleryDetail> items;
  final bool isLoading;
  final String emptyMessage;
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;
  final bool isDismissible;
  final void Function(int id)? onDismissed;
  final int totalCount;
  final int currentApiPage;
  final void Function(int page)? onPageChange;

  const GalleryListView({
    super.key,
    required this.items,
    required this.isLoading,
    this.emptyMessage = 'No items found',
    this.onRefresh,
    this.scrollController,
    this.isDismissible = false,
    this.onDismissed,
    this.totalCount = 0,
    this.currentApiPage = 1,
    this.onPageChange,
  });

  void _openReader(WidgetRef ref, int id) {
    ref.read(readerProvider.notifier).loadGallery(id);
    ref.read(navigationProvider.notifier).setScreen(CustomScreen.reader);
  }

  void _showDetail(BuildContext context, GalleryDetail item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetailBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final listingMode = settingsAsync.value?.listingMode ?? 'scroll';
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // 페이지네이션 모드는 별도로 처리 (로딩 중에도 바 표시)
    if (listingMode == 'pagination' && onPageChange != null) {
      final itemsPerPage = AppConfig.itemsPerPage;
      final totalPages = totalCount > 0
          ? (totalCount / itemsPerPage).ceil()
          : 1;

      return Listener(
        onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: _PaginatedView(
          items: items,
          isLoading: isLoading,
          currentPage: currentApiPage,
          totalPages: totalPages,
          onPageChange: onPageChange!,
          isDismissible: isDismissible,
          onDismissed: onDismissed,
          openReader: (id) => _openReader(ref, id),
          showDetail: (item) => _showDetail(context, item),
          scrollController: scrollController,
        ),
      );
    }

    // 스크롤 모드: 첫 로딩 시 전체 로딩 표시
    if (isLoading && items.isEmpty) return const LoadingWidget();

    if (items.isEmpty && !isLoading) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: theme.colorScheme.outline),
        ),
      );
    }

    // 스크롤 모드
    Widget listView = ListView.builder(
      controller: scrollController,
      physics: isTablet
          ? const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            )
          : const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: items.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = items[index];
        final card = GalleryCard(
          item: item,
          onTap: () => _openReader(ref, item.id),
          onLongPress: () => _showDetail(context, item),
        );

        if (isDismissible && onDismissed != null) {
          return Dismissible(
            key: Key(item.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => onDismissed!(item.id),
            child: card,
          );
        }

        return card;
      },
    );

    if (onRefresh != null) {
      listView = RefreshIndicator(onRefresh: onRefresh!, child: listView);
    }

    return Listener(
      onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      child: listView,
    );
  }
}

/// 페이지네이션 뷰 (API 페이지 기반)
class _PaginatedView extends StatelessWidget {
  final List<GalleryDetail> items;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final void Function(int page) onPageChange;
  final bool isDismissible;
  final void Function(int id)? onDismissed;
  final void Function(int id) openReader;
  final void Function(GalleryDetail item) showDetail;
  final ScrollController? scrollController;

  const _PaginatedView({
    required this.items,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
    this.isDismissible = false,
    this.onDismissed,
    required this.openReader,
    required this.showDetail,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 아이템 리스트 (상단)
        Expanded(
          child: isLoading
              ? const LoadingWidget()
              : ListView.builder(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final card = GalleryCard(
                      item: item,
                      onTap: () => openReader(item.id),
                      onLongPress: () => showDetail(item),
                    );

                    if (isDismissible && onDismissed != null) {
                      return Dismissible(
                        key: Key(item.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => onDismissed!(item.id),
                        child: card,
                      );
                    }

                    return card;
                  },
                ),
        ),
        // 페이지 네비게이션 바 (하단 - 항상 표시)
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
                onPressed: currentPage > 1 && !isLoading
                    ? () => onPageChange(1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1 && !isLoading
                    ? () => onPageChange(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading ? null : () => _showPageJumpDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$currentPage / $totalPages',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages && !isLoading
                    ? () => onPageChange(currentPage + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: currentPage < totalPages && !isLoading
                    ? () => onPageChange(totalPages)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPageJumpDialog(BuildContext context) {
    final controller = TextEditingController(text: currentPage.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 이동'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: '페이지 번호 (1-$totalPages)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= totalPages) {
                onPageChange(page);
                Navigator.pop(context);
              }
            },
            child: const Text('이동'),
          ),
        ],
      ),
    );
  }
}
