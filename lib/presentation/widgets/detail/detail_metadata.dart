import 'package:flutter/material.dart';
import '../../../models/types.dart';
import '../chips/tag_chip.dart';

class DetailMetadata extends StatelessWidget {
  final GalleryDetail item;

  const DetailMetadata({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.tags.isNotEmpty) ...[
            _buildSectionHeader(context, '태그'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags.map((tag) => TagChip(rawTag: tag)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          if (item.artists.isNotEmpty) ...[
            _buildSectionHeader(context, '작가'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.artists
                  .map(
                    (artist) => TagChip(rawTag: artist, typeOverride: 'artist'),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          _buildSectionHeader(context, '정보'),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'ID', item.id.toString()),
          _buildInfoRow(context, '타입', item.type),
          if (item.language != null)
            _buildInfoRow(context, '언어', item.language!),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
