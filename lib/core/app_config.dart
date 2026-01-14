/// 앱 전역 설정 상수
class AppConfig {
  // 캐시 설정
  static const int cacheMaxSize = 100;
  static const Duration cacheTtl = Duration(hours: 1);
  static const int recentViewedLimit = 50;

  // 이미지 뷰어
  static const double minImageScale = 1.0;
  static const double maxImageScale = 4.0;
  static const int readerPreloadRange = 3;

  // 페이지네이션
  static const int pageSize = 25;

  /// 페이지당 갤러리 ID 개수 (각 ID는 4바이트)
  static const int itemsPerPage = 25;

  /// Range 요청 바이트 크기 = itemsPerPage * 4
  static const int nozomiRangeBytes = itemsPerPage * 4; // 100 bytes

  // API 엔드포인트
  static const String cdnBase = 'https://ltn.gold-usergeneratedcontent.net';
  static const String tagIndexBase = 'https://tagindex.hitomi.la';

  // HTTP 헤더
  static const Map<String, String> defaultHeaders = {
    'Referer': 'https://hitomi.la/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };
}
