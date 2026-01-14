/// 설정 Repository
library;

import '../../data/data.dart';
import '../models/models.dart';

class SettingsRepository {
  /// 설정 조회
  Future<SettingsData> getSettings() async {
    try {
      final rows = await AppDatabase.querySettings();
      final defaults = SettingsData.defaults();

      String defaultLanguage = defaults.defaultLanguage;
      String theme = defaults.theme;
      String listingMode = defaults.listingMode;
      String readerMode = defaults.readerMode;
      String cardViewMode = defaults.cardViewMode;

      for (final row in rows) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        switch (key) {
          case 'defaultLanguage':
            defaultLanguage = value;
          case 'theme':
            theme = value;
          case 'listingMode':
            listingMode = value;
          case 'readerMode':
            readerMode = value;
          case 'cardViewMode':
            cardViewMode = value;
        }
      }

      return SettingsData(
        defaultLanguage: defaultLanguage,
        theme: theme,
        listingMode: listingMode,
        readerMode: readerMode,
        cardViewMode: cardViewMode,
      );
    } catch (_) {
      return SettingsData.defaults();
    }
  }

  /// 설정 저장
  Future<void> setSetting(String key, String value) async {
    await AppDatabase.upsertSetting(key, value);
  }
}
