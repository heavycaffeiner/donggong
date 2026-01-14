/// 즐겨찾기 데이터 모델
library;

class FavoritesData {
  List<int> favoriteId;
  List<String> favoriteArtist;
  List<String> favoriteTag;
  List<String> favoriteLanguage;
  List<String> favoriteGroup;
  List<String> favoriteParody;
  List<String> favoriteCharacter;

  FavoritesData({
    required this.favoriteId,
    required this.favoriteArtist,
    required this.favoriteTag,
    required this.favoriteLanguage,
    required this.favoriteGroup,
    required this.favoriteParody,
    required this.favoriteCharacter,
  });

  factory FavoritesData.empty() => FavoritesData(
    favoriteId: [],
    favoriteArtist: [],
    favoriteTag: [],
    favoriteLanguage: [],
    favoriteGroup: [],
    favoriteParody: [],
    favoriteCharacter: [],
  );

  factory FavoritesData.fromJson(Map<String, dynamic> json) => FavoritesData(
    favoriteId: (json['favoriteId'] as List?)?.cast<int>().toList() ?? [],
    favoriteArtist:
        (json['favoriteArtist'] as List?)?.cast<String>().toList() ?? [],
    favoriteTag: (json['favoriteTag'] as List?)?.cast<String>().toList() ?? [],
    favoriteLanguage:
        (json['favoriteLanguage'] as List?)?.cast<String>().toList() ?? [],
    favoriteGroup:
        (json['favoriteGroup'] as List?)?.cast<String>().toList() ?? [],
    favoriteParody:
        (json['favoriteParody'] as List?)?.cast<String>().toList() ?? [],
    favoriteCharacter:
        (json['favoriteCharacter'] as List?)?.cast<String>().toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'favoriteId': favoriteId,
    'favoriteArtist': favoriteArtist,
    'favoriteTag': favoriteTag,
    'favoriteLanguage': favoriteLanguage,
    'favoriteGroup': favoriteGroup,
    'favoriteParody': favoriteParody,
    'favoriteCharacter': favoriteCharacter,
  };
}
