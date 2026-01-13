import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/types.dart';
import '../../state/navigation_state.dart';
import '../../state/reader_state.dart';
import '../detail/detail_bottom_sheet.dart';
import 'gallery_card.dart';
import 'loading_widget.dart';
import '../../services/db_service.dart';

/// 공통 갤러리 리스트 위젯
class GalleryListView extends StatelessWidget {
  final List<GalleryDetail> items;
  final bool isLoading;
  final String emptyMessage;
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;
  final bool isDismissible;
  final void Function(int id)? onDismissed;

  const GalleryListView({
    super.key,
    required this.items,
    required this.isLoading,
    this.emptyMessage = 'No items found',
    this.onRefresh,
    this.scrollController,
    this.isDismissible = false,
    this.onDismissed,
  });

  void _openReader(BuildContext context, int id) {
    final readerState = Provider.of<ReaderState>(context, listen: false);
    final navState = Provider.of<NavigationState>(context, listen: false);

    DbService.addRecentViewed(id);
    readerState.loadGallery(id);
    navState.setScreen(CustomScreen.reader);
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && items.isEmpty) return const LoadingWidget();

    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: theme.colorScheme.outline),
        ),
      );
    }

    Widget listView = ListView.builder(
      controller: scrollController,
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
          onTap: () => _openReader(context, item.id),
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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: listView,
      ),
    );
  }
}
