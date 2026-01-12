import 'package:flutter/foundation.dart';
import '../../models/types.dart';
import '../../services/db_service.dart';

class SettingsState extends ChangeNotifier {
  SettingsData _settings = SettingsData.defaults();
  SettingsData get settings => _settings;

  SettingsState() {
    _init();
  }

  Future<void> _init() async {
    _settings = await DbService.getSettings();
    notifyListeners();
  }

  Future<void> setSetting(String key, String value) async {
    await DbService.setSetting(key, value);
    if (key == 'defaultLanguage') _settings.defaultLanguage = value;
    if (key == 'theme') _settings.theme = value;
    notifyListeners();
  }
}
