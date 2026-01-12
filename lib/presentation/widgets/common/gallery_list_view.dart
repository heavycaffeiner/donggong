import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/types.dart';
import '../../state/navigation_state.dart';
import '../../state/reader_state.dart';
import '../detail/detail_bottom_sheet.dart';
import 'gallery_card.dart';
import 'loading_widget.dart';
import '../../../services/db_service.dart';

/// 공통 갤러리 리스트 위젯
/// HomeScreen, RecentScreen, FavoritesScreen에서 공유
class GalleryListView extends StatelessWidget {
  final List<GalleryItem> items;
  final bool isLoading;
  final String emptyMessage;
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;
  final bool isDismissible;
  final void Function(int id)? onDismissed;
  final Widget? header;

  const GalleryListView({
    super.key,
    required this.items,
    required this.isLoading,
    this.emptyMessage = 'No items found',
    this.onRefresh,
    this.scrollController,
    this.isDismissible = false,
    this.onDismissed,
    this.header,
  });

  void _openReader(BuildContext context, int id) {
    final readerState = Provider.of<ReaderState>(context, listen: false);
    final navState = Provider.of<NavigationState>(context, listen: false);

    // Save to history
    DbService.addRecentViewed(id);

    readerState.loadGallery(id);
    navState.setScreen(CustomScreen.reader);
  }

  void _showDetail(BuildContext context, GalleryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetailBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Loading state
    if (isLoading && items.isEmpty) {
      return const LoadingWidget();
    }

    // Empty state
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: theme.colorScheme.outline),
        ),
      );
    }

    // Build list
    Widget listView = ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
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
          onTap: () => _openReader(context, item.id),
          onLongPress: () => _showDetail(context, item),
        );

        // Dismissible wrapper for Recent screen
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

    // Wrap with RefreshIndicator if onRefresh provided
    if (onRefresh != null) {
      listView = RefreshIndicator(onRefresh: onRefresh!, child: listView);
    }

    return listView;
  }
}
