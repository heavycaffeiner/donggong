import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:donggong/data/data.dart';
import 'package:donggong/core/app_config.dart';
import 'package:donggong/presentation/providers/providers.dart';

class GalleryCard extends ConsumerWidget {
  final GalleryDetail item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const GalleryCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final cardViewMode = settingsAsync.value?.cardViewMode ?? 'thumbnail';

    if (cardViewMode == 'thumbnail') {
      return _ThumbnailCard(item: item, onTap: onTap, onLongPress: onLongPress);
    } else {
      return _DetailedCard(item: item, onTap: onTap, onLongPress: onLongPress);
    }
  }
}

/// 썸네일 위주 카드 (큰 이미지 + 간단한 제목)
class _ThumbnailCard extends ConsumerWidget {
  final GalleryDetail item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ThumbnailCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final favoritesAsync = ref.watch(favoriteDataProvider);
    final isFav = favoritesAsync.value?.favoriteId.contains(item.id) ?? false;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.thumbnail,
                      httpHeaders: AppConfig.defaultHeaders,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerHigh,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.broken_image,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // 그라데이션 오버레이
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // 즐겨찾기 표시
                    if (isFav)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    // 타입 및 언어 칩
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        children: [
                          _buildOverlayChip(item.type, colorScheme),
                          if (item.language != null) ...[
                            const SizedBox(width: 4),
                            _buildOverlayChip(item.language!, colorScheme),
                          ],
                          const SizedBox(width: 4),
                          _buildOverlayChip(
                            '${item.pageCount} pages',
                            colorScheme,
                          ),
                          const SizedBox(width: 4),
                          _buildOverlayChip('ID: ${item.id}', colorScheme),
                        ],
                      ),
                    ),
                    // 제목
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayChip(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 정보 위주 카드 (작은 썸네일 + 상세 정보)
class _DetailedCard extends ConsumerWidget {
  final GalleryDetail item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DetailedCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final favoritesAsync = ref.watch(favoriteDataProvider);
    final isFav = favoritesAsync.value?.favoriteId.contains(item.id) ?? false;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 150,
                    minWidth: 110,
                  ),
                  child: SizedBox(
                    width: 110,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.thumbnail,
                          httpHeaders: AppConfig.defaultHeaders,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHigh,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.broken_image,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isFav)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.brush,
                              item.artists.isNotEmpty
                                  ? item.artists.join(', ')
                                  : 'N/A',
                              colorScheme,
                              textTheme,
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.group,
                              item.groups.isNotEmpty
                                  ? item.groups.join(', ')
                                  : 'N/A',
                              colorScheme,
                              textTheme,
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.photo_library,
                              '${item.pageCount} pages',
                              colorScheme,
                              textTheme,
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  _buildChip(item.type, colorScheme, textTheme),
                                  if (item.language != null)
                                    _buildChip(
                                      item.language!,
                                      colorScheme,
                                      textTheme,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'ID: ${item.id}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 12, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String text, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
