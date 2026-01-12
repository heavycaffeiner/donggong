
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

  factory HitomiFile.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return HitomiFile(
      hash: json['hash'] as String,
      name: json['name'] as String,
      width: parseInt(json['width']),
      height: parseInt(json['height']),
      hasWebp: parseInt(json['haswebp']),
    );
  }
}

class HitomiTag {
  final String tag;
  final String url;
  final String? female;
  final String? male;

  HitomiTag({required this.tag, required this.url, this.female, this.male});

  factory HitomiTag.fromJson(Map<String, dynamic> json) {
    return HitomiTag(
      tag: json['tag'] as String,
      url: json['url'] as String,
      female: json['female'] as String?,
      male: json['male'] as String?,
    );
  }
}

class GalleryItem {
  final int id;
  final String title;
  final String thumbnail;
  final List<String> artists;
  final String type;
  final String? language;
  final List<String> tags;

  GalleryItem({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.artists,
    required this.type,
    this.language,
    required this.tags,
  });
}

class GalleryDetail extends GalleryItem {
  final List<GalleryImage> images;

  GalleryDetail({
    required super.id,
    required super.title,
    required super.thumbnail,
    required super.artists,
    required super.type,
    super.language,
    required super.tags,
    required this.images,
  });

  factory GalleryDetail.empty() {
    return GalleryDetail(
      id: 0,
      title: '',
      thumbnail: '',
      artists: [],
      type: '',
      tags: [],
      images: [],
    );
  }

  factory GalleryDetail.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic input, {bool isTag = false}) {
      if (input is! List) return [];
      return input.map((e) {
        if (e is String) return e;
        if (e is Map) {
          if (e.containsKey('artist')) return e['artist'] as String;
          if (e.containsKey('tag')) {
            final tag = e['tag'] as String;
            if (!isTag) return tag; // For artists etc (though usually just string)
            
            // Check for namespaced tags
            final female = e['female'] == '1' || e['female'] == 1;
            final male = e['male'] == '1' || e['male'] == 1;
            
            if (female) return 'female:$tag';
            if (male) return 'male:$tag';
            return tag;
          }
        }
        return '';
      }).where((e) => e.isNotEmpty).cast<String>().toList();
    }

    return GalleryDetail(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      artists: parseList(json['artists']),
      type: json['type'] ?? '',
      language: json['language'],
      tags: parseList(json['tags'], isTag: true),
      images: [],
    );
  }

  // Helper to re-serialize if needed, though we use raw JSON from API for cache
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail': thumbnail,
    'artists': artists,
    'type': type,
    'language': language,
    'tags': tags,
    // images omitted or simplified
  };
}

class GalleryImage {
  final String url;
  final int width;
  final int height;

  GalleryImage({required this.url, required this.width, required this.height});
}

class TagSuggestion {
  final String tag;
  final int count;
  final String type;

  TagSuggestion({required this.tag, required this.count, required this.type});

  factory TagSuggestion.fromJson(List<dynamic> json) {
    final countVal = json[1];
    int count = 0;
    if (countVal is int) {
      count = countVal;
    } else if (countVal is String) {
      count = int.tryParse(countVal) ?? 0;
    }

    return TagSuggestion(
      tag: json[0] as String,
      count: count,
      type: json[2] as String,
    );
  }
}

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

  factory FavoritesData.empty() {
    return FavoritesData(
      favoriteId: [],
      favoriteArtist: [],
      favoriteTag: [],
      favoriteLanguage: [],
    );
  }

  factory FavoritesData.fromJson(Map<String, dynamic> json) {
    return FavoritesData(
      favoriteId: (json['favoriteId'] as List<dynamic>?)?.cast<int>().toList() ?? [],
      favoriteArtist: (json['favoriteArtist'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      favoriteTag: (json['favoriteTag'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      favoriteLanguage: (json['favoriteLanguage'] as List<dynamic>?)?.cast<String>().toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'favoriteId': favoriteId,
    'favoriteArtist': favoriteArtist,
    'favoriteTag': favoriteTag,
    'favoriteLanguage': favoriteLanguage,
  };
}

class SettingsData {
  String defaultLanguage;
  String theme;

  SettingsData({required this.defaultLanguage, required this.theme});

  factory SettingsData.defaults() {
    return SettingsData(defaultLanguage: 'korean', theme: 'dark');
  }
}

enum CustomScreen { home, recentViewed, favorites, settings, reader }
