/// 설정 데이터 모델
library;

class SettingsData {
  String defaultLanguage;
  String theme;

  SettingsData({required this.defaultLanguage, required this.theme});

  factory SettingsData.defaults() =>
      SettingsData(defaultLanguage: 'korean', theme: 'dark');

  SettingsData copyWith({String? defaultLanguage, String? theme}) =>
      SettingsData(
        defaultLanguage: defaultLanguage ?? this.defaultLanguage,
        theme: theme ?? this.theme,
      );
}
