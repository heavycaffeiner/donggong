/// 갤러리 관련 DTO
library;

import 'hitomi_dto.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gallery DTO
// ─────────────────────────────────────────────────────────────────────────────

class GalleryImage {
  final String url;
  final int width;
  final int height;

  const GalleryImage({
    required this.url,
    required this.width,
    required this.height,
  });
}

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

  const GalleryDetail({
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

  factory GalleryDetail.empty() => const GalleryDetail(
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

  GalleryDetail copyWith({
    int? id,
    String? title,
    String? thumbnail,
    List<String>? artists,
    List<String>? groups,
    List<String>? characters,
    List<String>? parodys,
    String? type,
    String? language,
    List<String>? tags,
    List<GalleryImage>? images,
  }) => GalleryDetail(
    id: id ?? this.id,
    title: title ?? this.title,
    thumbnail: thumbnail ?? this.thumbnail,
    artists: artists ?? this.artists,
    groups: groups ?? this.groups,
    characters: characters ?? this.characters,
    parodys: parodys ?? this.parodys,
    type: type ?? this.type,
    language: language ?? this.language,
    tags: tags ?? this.tags,
    images: images ?? this.images,
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

  /// 검색 쿼리 매칭
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
