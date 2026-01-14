import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:donggong/domain/domain.dart';
import 'package:donggong/shared/shared.dart';
import 'package:donggong/presentation/providers/providers.dart';

class TagChip extends ConsumerWidget {
  final String rawTag;
  final String? typeOverride;

  const TagChip({super.key, required this.rawTag, this.typeOverride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final parts = rawTag.split(':');
    final type = typeOverride ?? parts[0];
    final cleanTag = parts.length > 1
        ? parts.sublist(1).join(':').replaceAll('_', ' ')
        : (typeOverride != null ? rawTag : rawTag).replaceAll('_', ' ');

    final searchVal = parts.length > 1
        ? parts.sublist(1).join(':').replaceAll(' ', '_')
        : cleanTag.replaceAll(' ', '_');

    final favValue = searchVal;

    final favoritesAsync = ref.watch(favoriteProvider);
    final favData = favoritesAsync.favoritesData;
    final isFav = _checkFavorite(favData, type, favValue);

    Color? chipColor;
    Color? labelColor;
    Widget icon;

    if (type == 'female') {
      chipColor = Colors.pinkAccent.withValues(alpha: 0.1);
      labelColor = Colors.pinkAccent;
      icon = const Icon(Icons.female, size: 14, color: Colors.pinkAccent);
    } else if (type == 'male') {
      chipColor = Colors.blueAccent.withValues(alpha: 0.1);
      labelColor = Colors.blueAccent;
      icon = const Icon(Icons.male, size: 14, color: Colors.blueAccent);
    } else if (type == 'artist') {
      labelColor = theme.colorScheme.onSurface;
      icon = const Icon(Icons.person, size: 14);
    } else {
      labelColor = theme.colorScheme.onSurfaceVariant;
      icon = Icon(
        Icons.label_outline,
        size: 14,
        color: theme.colorScheme.outline,
      );
    }

    if (isFav) {
      chipColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
      labelColor = theme.colorScheme.primary;
      icon = Icon(Icons.favorite, size: 14, color: theme.colorScheme.primary);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Material(
        color: chipColor ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isFav
              ? BorderSide.none
              : BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
        ),
        child: InkWell(
          onTap: () => _onTap(context, ref, rawTag),
          onLongPress: () => _onLongPress(context, ref, type, favValue, isFav),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 4),
                Text(
                  cleanTag,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: isFav ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _checkFavorite(FavoritesData data, String type, String value) {
    switch (type) {
      case 'gallery':
        return data.favoriteId.contains(int.tryParse(value) ?? 0);
      case 'female':
        return data.favoriteTag.contains('female:$value');
      case 'male':
        return data.favoriteTag.contains('male:$value');
      case 'artist':
        return data.favoriteArtist.contains(value);
      case 'group':
        return data.favoriteGroup.contains(value);
      case 'series':
        return data.favoriteParody.contains(value);
      case 'character':
        return data.favoriteCharacter.contains(value);
      case 'language':
        return data.favoriteLanguage.contains(value);
      case 'tag':
        return data.favoriteTag.contains('tag:$value');
      default:
        return false;
    }
  }

  void _onTap(BuildContext context, WidgetRef ref, String query) {
    final screen = ref.read(navigationProvider);
    final settingsAsync = ref.read(settingsProvider);
    final settings = settingsAsync.value ?? SettingsData.defaults();

    String finalQuery = query.replaceAll(' ', '_');
    if (typeOverride != null) {
      finalQuery = '$typeOverride:$finalQuery';
    }

    // Add to recent search
    ref.read(recentSearchProvider.notifier).add(finalQuery);

    ref.read(searchProvider.notifier).setQuery(finalQuery);
    Navigator.pop(context);

    if (screen == CustomScreen.favorites) {
      ref.read(favoriteProvider.notifier).loadFavorites(query: finalQuery);
    } else {
      ref.read(navigationProvider.notifier).setScreen(CustomScreen.home);
      ref
          .read(galleryProvider.notifier)
          .loadGalleries(
            reset: true,
            query: finalQuery,
            defaultLang: settings.defaultLanguage,
          );
    }
  }

  Future<void> _onLongPress(
    BuildContext context,
    WidgetRef ref,
    String type,
    String value,
    bool currentFav,
  ) async {
    print('type: $type, value: $value, currentFav: $currentFav');
    await ref.read(favoriteProvider.notifier).toggleFavorite(type, value);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentFav ? "'$value' 즐겨찾기 해제됨" : "'$value' 즐겨찾기 추가됨"),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
