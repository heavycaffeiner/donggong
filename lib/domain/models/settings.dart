/// 설정 데이터 모델
library;

class SettingsData {
  final String defaultLanguage;
  final String theme;
  final String listingMode; // 'scroll' | 'pagination'
  final String readerMode; // 'verticalPage' | 'horizontalPage' | 'webtoon'
  final String cardViewMode; // 'thumbnail' | 'detailed'

  const SettingsData({
    required this.defaultLanguage,
    required this.theme,
    required this.listingMode,
    required this.readerMode,
    required this.cardViewMode,
  });

  factory SettingsData.defaults() => const SettingsData(
    defaultLanguage: 'korean',
    theme: 'dark',
    listingMode: 'scroll',
    readerMode: 'verticalPage',
    cardViewMode: 'thumbnail',
  );

  SettingsData copyWith({
    String? defaultLanguage,
    String? theme,
    String? listingMode,
    String? readerMode,
    String? cardViewMode,
  }) => SettingsData(
    defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    theme: theme ?? this.theme,
    listingMode: listingMode ?? this.listingMode,
    readerMode: readerMode ?? this.readerMode,
    cardViewMode: cardViewMode ?? this.cardViewMode,
  );
}
