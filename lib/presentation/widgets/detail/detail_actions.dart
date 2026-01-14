import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:donggong/data/data.dart';
import 'package:donggong/shared/shared.dart';
import 'package:donggong/presentation/providers/providers.dart';

class DetailActions extends ConsumerWidget {
  final GalleryDetail item;

  const DetailActions({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteDataProvider);
    final isFav = favoritesAsync.value?.favoriteId.contains(item.id) ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ref.read(readerProvider.notifier).loadGallery(item.id);
                ref
                    .read(navigationProvider.notifier)
                    .setScreen(CustomScreen.reader);
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
            onPressed: () => ref
                .read(favoriteProvider.notifier)
                .toggleFavorite('gallery', item.id.toString()),
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
