/// Hitomi API 응답 파싱용 DTO
library;

// ─────────────────────────────────────────────────────────────────────────────
// 공통 헬퍼
// ─────────────────────────────────────────────────────────────────────────────

List<String> parseTagList(dynamic input, {bool isTag = false}) {
  if (input is! List) return [];
  return input
      .map((e) {
        if (e is String) return e;
        if (e is Map) {
          if (e.containsKey('artist')) return e['artist'] as String;
          if (e.containsKey('group')) return e['group'] as String;
          if (e.containsKey('character')) return e['character'] as String;
          if (e.containsKey('parody')) return e['parody'] as String;
          if (e.containsKey('tag')) {
            final tag = e['tag'] as String;
            if (!isTag) return tag;
            final female = e['female'] == '1' || e['female'] == 1;
            final male = e['male'] == '1' || e['male'] == 1;
            if (female) return 'female:$tag';
            if (male) return 'male:$tag';
            return 'tag:$tag';
          }
        }
        return '';
      })
      .where((e) => e.isNotEmpty)
      .cast<String>()
      .toList();
}

int safeParseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hitomi API DTO
// ─────────────────────────────────────────────────────────────────────────────

class HitomiFile {
  final String hash;
  final String name;
  final int width;
  final int height;
  final int hasWebp;

  const HitomiFile({
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

  const HitomiTag({
    required this.tag,
    required this.url,
    this.female,
    this.male,
  });

  factory HitomiTag.fromJson(Map<String, dynamic> json) => HitomiTag(
    tag: json['tag'] as String,
    url: json['url'] as String,
    female: json['female'] as String?,
    male: json['male'] as String?,
  );
}

class TagSuggestion {
  final String tag;
  final int count;
  final String type;

  const TagSuggestion({
    required this.tag,
    required this.count,
    required this.type,
  });

  factory TagSuggestion.fromJson(List<dynamic> json) => TagSuggestion(
    tag: json[0] as String,
    count: safeParseInt(json[1]),
    type: json[2] as String,
  );
}
