import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/domain.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value ?? SettingsData.defaults();
    final theme = Theme.of(context);
    final languages = ['all', 'korean', 'english', 'japanese'];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 기본 언어
            _buildSectionTitle('기본 언어', theme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: languages.map((lang) {
                final isSelected = settings.defaultLanguage == lang;
                return ChoiceChip(
                  label: Text(lang),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('defaultLanguage', lang);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // 테마
            _buildSectionTitle('테마', theme),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Dark'),
                  selected: settings.theme == 'dark',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('theme', 'dark');
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('OLED Dark'),
                  selected: settings.theme == 'oledDark',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('theme', 'oledDark');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 리스팅 모드
            _buildSectionTitle('리스팅 모드', theme),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('무한 스크롤'),
                  selected: settings.listingMode == 'scroll',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('listingMode', 'scroll');
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('페이지'),
                  selected: settings.listingMode == 'pagination',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('listingMode', 'pagination');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 뷰어 모드
            _buildSectionTitle('뷰어 모드', theme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('세로 페이지'),
                  selected: settings.readerMode == 'verticalPage',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('readerMode', 'verticalPage');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('가로 페이지'),
                  selected: settings.readerMode == 'horizontalPage',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('readerMode', 'horizontalPage');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('웹툰 (연속 스크롤)'),
                  selected: settings.readerMode == 'webtoon',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('readerMode', 'webtoon');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 카드 뷰 모드
            _buildSectionTitle('카드 뷰 모드', theme),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('썸네일 위주'),
                  selected: settings.cardViewMode == 'thumbnail',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('cardViewMode', 'thumbnail');
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('정보 위주'),
                  selected: settings.cardViewMode == 'detailed',
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('cardViewMode', 'detailed');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 즐겨찾기 백업/복원
            _buildSectionTitle('즐겨찾기 백업/복원', theme),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () => _exportFavorites(context),
                  child: const Text('백업 (Export)'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () => _importFavorites(context),
                  child: const Text('복원 (Import)'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 위험 구역
            _buildSectionTitle('위험 구역', theme),
            const SizedBox(height: 12),
            Column(
              children: [
                FilledButton.tonal(
                  onPressed: _isValidating
                      ? null
                      : () => _validateFavorites(context),
                  child: _isValidating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('삭제된 항목 정리 (Clean Up)'),
                ),
                FilledButton.tonal(
                  onPressed: _isValidating
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('즐겨찾기 초기화'),
                              content: const Text(
                                '모든 즐겨찾기 항목이 삭제됩니다.\n계속하시겠습니까?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('초기화'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            await ref
                                .read(favoriteProvider.notifier)
                                .clearAllFavorites();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('즐겨찾기가 초기화되었습니다.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('즐겨찾기 초기화 (Reset Favorites)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Future<void> _exportFavorites(BuildContext context) async {
    try {
      final repo = ref.read(favoriteRepositoryProvider);
      final data = await repo.export();
      final jsonString = jsonEncode(data.toJson());
      final now = DateTime.now();
      final fileName =
          'donggong_backup_${DateFormat('yyyyMMdd_HHmm').format(now)}.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Favorites',
        fileName: fileName,
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: bytes,
      );

      if (outputFile != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importFavorites(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString);
        final data = FavoritesData.fromJson(jsonMap);

        final repo = ref.read(favoriteRepositoryProvider);
        await repo.import(data);
        await ref.read(favoriteProvider.notifier).loadFavorites();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorites imported successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _validateFavorites(BuildContext context) async {
    setState(() => _isValidating = true);

    try {
      final invalidIds = await ref
          .read(favoriteProvider.notifier)
          .validateFavorites();

      if (!context.mounted) return;

      if (invalidIds.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모든 즐겨찾기 항목이 유효합니다.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${invalidIds.length}개의 삭제된/유효하지 않은 항목을 발견했습니다.'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '일괄 삭제',
              onPressed: () async {
                await ref
                    .read(favoriteProvider.notifier)
                    .removeFavorites(invalidIds);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('삭제 완료')));
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('검사 중 오류 발생: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }
}
