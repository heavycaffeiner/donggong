import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/types.dart';
import '../../models/types.dart' show CustomScreen;
import '../../state/favorite_state.dart';
import '../../state/gallery_state.dart';
import '../../state/navigation_state.dart';
import '../../state/search_state.dart';
import '../../state/settings_state.dart';

class TagChip extends StatelessWidget {
  final String rawTag;
  final String? typeOverride;

  const TagChip({super.key, required this.rawTag, this.typeOverride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favState = Provider.of<FavoriteState>(context);

    final parts = rawTag.split(':');
    final type = typeOverride ?? parts[0];
    final cleanTag = parts.length > 1
        ? parts.sublist(1).join(':').replaceAll('_', ' ')
        : (typeOverride != null ? rawTag : rawTag).replaceAll('_', ' ');

    final searchVal = parts.length > 1
        ? parts.sublist(1).join(':').replaceAll(' ', '_')
        : cleanTag.replaceAll(' ', '_');

    final favType = type == 'female' || type == 'male' ? 'tag' : type;
    final favValue = typeOverride != null ? searchVal : rawTag;

    final isFav = favState.isFavorite(favType, favValue);

    Color? chipColor;
    Color? labelColor;
    Widget icon; // Was Widget? icon;

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
          onTap: () => _onTap(context, rawTag),
          onLongPress: () => _onLongPress(context, favType, favValue, isFav),
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

  void _onTap(BuildContext context, String query) {
    final navState = Provider.of<NavigationState>(context, listen: false);
    final galleryState = Provider.of<GalleryState>(context, listen: false);
    final favState = Provider.of<FavoriteState>(context, listen: false);
    final searchState = Provider.of<SearchState>(context, listen: false);
    final settingsState = Provider.of<SettingsState>(context, listen: false);

    String finalQuery = query.replaceAll(' ', '_');
    if (typeOverride == 'artist') {
      finalQuery = 'artist:${rawTag.replaceAll(' ', '_')}';
    }

    searchState.setQuery(finalQuery);
    Navigator.pop(context);

    if (navState.screen == CustomScreen.favorites) {
      favState.loadFavorites(query: finalQuery);
    } else {
      navState.setScreen(CustomScreen.home);
      galleryState.loadGalleries(
        reset: true,
        query: finalQuery,
        defaultLang: settingsState.settings.defaultLanguage,
      );
    }
  }

  Future<void> _onLongPress(
    BuildContext context,
    String type,
    String value,
    bool currentFav,
  ) async {
    final favState = Provider.of<FavoriteState>(context, listen: false);
    await favState.toggleFavorite(type, value);

    // Haptic feedback
    // Feedback.forLongPress(context); // Optional, usually built-in to LongPress but InkWell might need explicit call

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
