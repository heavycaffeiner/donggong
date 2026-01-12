import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/types.dart';
import '../presentation/state/favorite_state.dart';
import '../presentation/state/settings_state.dart';
import '../services/db_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    final settingsState = Provider.of<SettingsState>(context);
    final theme = Theme.of(context);
    final languages = ['all', 'korean', 'english', 'japanese'];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '기본 언어',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: languages.map((lang) {
                final isSelected =
                    settingsState.settings.defaultLanguage == lang;
                return ChoiceChip(
                  label: Text(lang),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      settingsState.setSetting('defaultLanguage', lang);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            Text(
              '테마',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Dark'),
                  selected: settingsState.settings.theme == 'dark',
                  onSelected: (selected) {
                    if (selected) settingsState.setSetting('theme', 'dark');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('OLED Dark'),
                  selected: settingsState.settings.theme == 'oledDark',
                  onSelected: (selected) {
                    if (selected) settingsState.setSetting('theme', 'oledDark');
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              '즐겨찾기 백업/복원',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    try {
                      final data = await DbService.export();
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

                      if (outputFile != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved successfully')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('백업 (Export)'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['json'],
                          );

                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);
                        final jsonString = await file.readAsString();
                        final jsonMap = jsonDecode(jsonString);
                        final data = FavoritesData.fromJson(jsonMap);

                        await DbService.import(data);
                        if (context.mounted) {
                          final favState = Provider.of<FavoriteState>(
                            context,
                            listen: false,
                          );
                          // Force reload to update UI
                          await favState.loadFavorites();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Favorites imported successfully',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Import failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('복원 (Import)'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              '유효성 검사',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateFavorites(BuildContext context) async {
    setState(() => _isValidating = true);

    try {
      final favState = Provider.of<FavoriteState>(context, listen: false);
      final invalidIds = await favState.validateFavorites();

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
                await favState.removeFavorites(invalidIds);
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
