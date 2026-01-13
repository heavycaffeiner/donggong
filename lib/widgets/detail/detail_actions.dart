import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/types.dart';
// For enum
import '../../state/favorite_state.dart';
import '../../state/navigation_state.dart';
import '../../state/reader_state.dart';

class DetailActions extends StatelessWidget {
  final GalleryDetail item;

  const DetailActions({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // New states
    // Note: We need to ensure these providers are available in context (main.dart update needed)
    final favState = Provider.of<FavoriteState>(context);
    final navState = Provider.of<NavigationState>(context, listen: false);
    final readerState = Provider.of<ReaderState>(context, listen: false);

    final isFav = favState.isFavorite('gallery', item.id);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                readerState.loadGallery(item.id);
                navState.setScreen(CustomScreen.reader);
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('읽기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () =>
                favState.toggleFavorite('gallery', item.id.toString()),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isFav ? colorScheme.primaryContainer : null,
            ),
          ),
        ],
      ),
    );
  }
}
