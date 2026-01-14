import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:donggong/data/data.dart';
import 'package:donggong/presentation/widgets/widgets.dart';

class DetailMetadata extends StatelessWidget {
  final GalleryDetail item;

  const DetailMetadata({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.artists.isNotEmpty) ...[
              _buildSectionHeader(context, '작가'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.artists
                    .map(
                      (artist) =>
                          TagChip(rawTag: artist, typeOverride: 'artist'),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (item.groups.isNotEmpty) ...[
              _buildSectionHeader(context, '그룹'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.groups
                    .map(
                      (group) => TagChip(rawTag: group, typeOverride: 'group'),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (item.characters.isNotEmpty) ...[
              _buildSectionHeader(context, '캐릭터'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.characters
                    .map(
                      (character) =>
                          TagChip(rawTag: character, typeOverride: 'character'),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (item.parodys.isNotEmpty) ...[
              _buildSectionHeader(context, '시리즈'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.parodys
                    .map(
                      (parody) =>
                          TagChip(rawTag: parody, typeOverride: 'series'),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
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
            _buildSectionHeader(context, '정보'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CommonChip(
                  label: 'ID: ${item.id}',
                  icon: Icons.copy_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  labelColor: Theme.of(context).colorScheme.primary,
                  iconColor: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.id.toString()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID가 복사되었습니다'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
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
}
