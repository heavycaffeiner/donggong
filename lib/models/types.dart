/// 공통 JSON 파싱 헬퍼 (List<Map> → List<String>)
List<String> parseTagList(dynamic input, {bool isTag = false}) {
  if (input is! List) return [];
  return input
      .map((e) {
        if (e is String) return e;
        if (e is Map) {
          // artist 필드
          if (e.containsKey('artist')) return e['artist'] as String;
          // group 필드
          if (e.containsKey('group')) return e['group'] as String;
          // character 필드
          if (e.containsKey('character')) return e['character'] as String;
          // parody 필드
          if (e.containsKey('parody')) return e['parody'] as String;
          // tag 필드
          if (e.containsKey('tag')) {
            final tag = e['tag'] as String;
            if (!isTag) return tag;
            // namespaced tags
            final female = e['female'] == '1' || e['female'] == 1;
            final male = e['male'] == '1' || e['male'] == 1;
            if (female) return 'female:$tag';
            if (male) return 'male:$tag';
            return tag;
          }
        }
        return '';
      })
      .where((e) => e.isNotEmpty)
      .cast<String>()
      .toList();
}

/// 안전한 int 파싱
int safeParseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hitomi 관련 타입 (API 응답 파싱용)
// ─────────────────────────────────────────────────────────────────────────────

class HitomiFile {
  final String hash;
  final String name;
  final int width;
  final int height;
  final int hasWebp;

  HitomiFile({
    required this.hash,
    required this.name,
    required this.width,
    required this.height,
    required this.hasWebp,
  });

  factory HitomiFile.fromJson(Map<String, dynamic> json) => HitomiFile(
    hash: json['hash'] as String,
    name: json['name'] as String,
    width: safeParseInt(json['width']),
    height: safeParseInt(json['height']),
    hasWebp: safeParseInt(json['haswebp']),
  );
}

class HitomiTag {
  final String tag;
  final String url;
  final String? female;
  final String? male;

  HitomiTag({required this.tag, required this.url, this.female, this.male});

  factory HitomiTag.fromJson(Map<String, dynamic> json) => HitomiTag(
    tag: json['tag'] as String,
    url: json['url'] as String,
    female: json['female'] as String?,
    male: json['male'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 갤러리 모델 (통합)
// ─────────────────────────────────────────────────────────────────────────────

class GalleryImage {
  final String url;
  final int width;
  final int height;

  GalleryImage({required this.url, required this.width, required this.height});
}

/// 갤러리 아이템 (목록 + 상세 통합)
class GalleryDetail {
  final int id;
  final String title;
  final String thumbnail;
  final List<String> artists;
  final List<String> groups;
  final List<String> characters;
  final List<String> parodys;
  final String type;
  final String? language;
  final List<String> tags;
  final List<GalleryImage> images;

  GalleryDetail({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.artists,
    this.groups = const [],
    this.characters = const [],
    this.parodys = const [],
    required this.type,
    this.language,
    required this.tags,
    this.images = const [],
  });

  factory GalleryDetail.empty() => GalleryDetail(
    id: 0,
    title: '',
    thumbnail: '',
    artists: [],
    type: '',
    tags: [],
  );

  factory GalleryDetail.fromJson(Map<String, dynamic> json) => GalleryDetail(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    title: json['title'] ?? '',
    thumbnail: json['thumbnail'] ?? '',
    artists: parseTagList(json['artists']),
    groups: parseTagList(json['groups']),
    characters: parseTagList(json['characters']),
    parodys: parseTagList(json['parodys']),
    type: json['type'] ?? '',
    language: json['language'],
    tags: parseTagList(json['tags'], isTag: true),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail': thumbnail,
    'artists': artists,
    'groups': groups,
    'characters': characters,
    'parodys': parodys,
    'type': type,
    'language': language,
    'tags': tags,
  };

  /// 검색 쿼리 매칭 (FavoriteState에서 이동)
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final tokens = query.trim().split(RegExp(r'\s+'));
    return tokens.every(_matchesToken);
  }

  bool _matchesToken(String token) {
    final normalized = token.replaceAll('_', ' ').toLowerCase();
    String? searchType;
    String searchValue = normalized;

    if (normalized.contains(':')) {
      final colonIndex = normalized.indexOf(':');
      final prefix = normalized.substring(0, colonIndex);
      const validPrefixes = [
        'artist',
        'female',
        'male',
        'tag',
        'series',
        'group',
        'character',
        'parody',
        'language',
      ];
      if (validPrefixes.contains(prefix)) {
        searchType = prefix;
        searchValue = normalized.substring(colonIndex + 1).trim();
      }
    }

    switch (searchType) {
      case 'artist':
        return artists.any((a) => a.toLowerCase().contains(searchValue));
      case 'female':
      case 'male':
        final fullTag = '$searchType:$searchValue';
        return tags.any(
          (t) => t.toLowerCase().replaceAll('_', ' ').contains(fullTag),
        );
      case 'tag':
        return tags.any(
          (t) => t.toLowerCase().replaceAll('_', ' ').contains(searchValue),
        );
      case 'language':
        return language?.toLowerCase().contains(searchValue) ?? false;
      case 'series':
      case 'parody':
        return parodys.any((p) => p.toLowerCase().contains(searchValue));
      case 'group':
        return groups.any((g) => g.toLowerCase().contains(searchValue));
      case 'character':
        return characters.any((c) => c.toLowerCase().contains(searchValue));
      default:
        // 일반 검색: 모든 필드에서 매칭
        return title.toLowerCase().contains(searchValue) ||
            artists.any((a) => a.toLowerCase().contains(searchValue)) ||
            tags.any(
              (t) => t.toLowerCase().replaceAll('_', ' ').contains(searchValue),
            ) ||
            groups.any((g) => g.toLowerCase().contains(searchValue)) ||
            characters.any((c) => c.toLowerCase().contains(searchValue)) ||
            parodys.any((p) => p.toLowerCase().contains(searchValue));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 태그 자동완성
// ─────────────────────────────────────────────────────────────────────────────

class TagSuggestion {
  final String tag;
  final int count;
  final String type;

  TagSuggestion({required this.tag, required this.count, required this.type});

  factory TagSuggestion.fromJson(List<dynamic> json) => TagSuggestion(
    tag: json[0] as String,
    count: safeParseInt(json[1]),
    type: json[2] as String,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 즐겨찾기 데이터
// ─────────────────────────────────────────────────────────────────────────────

class FavoritesData {
  List<int> favoriteId;
  List<String> favoriteArtist;
  List<String> favoriteTag;
  List<String> favoriteLanguage;

  FavoritesData({
    required this.favoriteId,
    required this.favoriteArtist,
    required this.favoriteTag,
    required this.favoriteLanguage,
  });

  factory FavoritesData.empty() => FavoritesData(
    favoriteId: [],
    favoriteArtist: [],
    favoriteTag: [],
    favoriteLanguage: [],
  );

  factory FavoritesData.fromJson(Map<String, dynamic> json) => FavoritesData(
    favoriteId: (json['favoriteId'] as List?)?.cast<int>().toList() ?? [],
    favoriteArtist:
        (json['favoriteArtist'] as List?)?.cast<String>().toList() ?? [],
    favoriteTag: (json['favoriteTag'] as List?)?.cast<String>().toList() ?? [],
    favoriteLanguage:
        (json['favoriteLanguage'] as List?)?.cast<String>().toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'favoriteId': favoriteId,
    'favoriteArtist': favoriteArtist,
    'favoriteTag': favoriteTag,
    'favoriteLanguage': favoriteLanguage,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// 설정
// ─────────────────────────────────────────────────────────────────────────────

class SettingsData {
  String defaultLanguage;
  String theme;

  SettingsData({required this.defaultLanguage, required this.theme});

  factory SettingsData.defaults() =>
      SettingsData(defaultLanguage: 'korean', theme: 'dark');
}

// ─────────────────────────────────────────────────────────────────────────────
// 화면 열거형 (switch 문 제거용 index/title 포함)
// ─────────────────────────────────────────────────────────────────────────────

enum CustomScreen {
  home(0, '홈'),
  recentViewed(1, '최근 본 작품'),
  favorites(2, '즐겨찾기'),
  settings(3, '설정'),
  reader(-1, '');

  final int tabIndex;
  final String title;
  const CustomScreen(this.tabIndex, this.title);

  /// IndexedStack 인덱스용 (reader는 0 반환)
  int get stackIndex => tabIndex < 0 ? 0 : tabIndex;
}
