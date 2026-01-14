/// 설정 Repository
library;

import '../../data/data.dart';
import '../models/models.dart';

class SettingsRepository {
  /// 설정 조회
  Future<SettingsData> getSettings() async {
    try {
      final rows = await AppDatabase.querySettings();
      final settings = SettingsData.defaults();
      for (final row in rows) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        if (key == 'defaultLanguage') settings.defaultLanguage = value;
        if (key == 'theme') settings.theme = value;
      }
      return settings;
    } catch (_) {
      return SettingsData.defaults();
    }
  }

  /// 설정 저장
  Future<void> setSetting(String key, String value) async {
    await AppDatabase.upsertSetting(key, value);
  }
}
