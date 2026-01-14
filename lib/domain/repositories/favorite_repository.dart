/// 즐겨찾기 Repository (DB + DTO 변환)
library;

import 'dart:convert';
import '../../data/data.dart';
import '../models/models.dart';

class FavoriteRepository {
  /// 즐겨찾기 데이터 조회
  Future<FavoritesData> getFavorites() async {
    final data = FavoritesData.empty();
    try {
      final rows = await AppDatabase.queryFavorites();
      for (final row in rows) {
        final type = row['type'] as String;
        final value = row['value'] as String;
        switch (type) {
          case 'gallery':
            data.favoriteId.add(int.parse(value));
          case 'artist':
            data.favoriteArtist.add(value);
          case 'female':
            data.favoriteTag.add('female:$value');
          case 'male':
            data.favoriteTag.add('male:$value');
          case 'tag':
            data.favoriteTag.add('tag:$value');
          case 'language':
            data.favoriteLanguage.add(value);
          case 'group':
            data.favoriteGroup.add(value);
          case 'series':
            data.favoriteParody.add(value);
          case 'character':
            data.favoriteCharacter.add(value);
        }
      }
    } catch (_) {}
    return data;
  }

  /// 즐겨찾기 존재 여부
  bool isFavorite(FavoritesData data, String type, dynamic value) {
    switch (type) {
      case 'gallery':
        return data.favoriteId.contains(int.parse(value));
      case 'artist':
        return data.favoriteArtist.contains(value);
      case 'female':
        return data.favoriteTag.contains('female:$value');
      case 'male':
        return data.favoriteTag.contains('male:$value');
      case 'tag':
        return data.favoriteTag.contains('tag:$value');
      case 'language':
        return data.favoriteLanguage.contains(value);
      case 'group':
        return data.favoriteGroup.contains(value);
      case 'series':
        return data.favoriteParody.contains(value);
      case 'character':
        return data.favoriteCharacter.contains(value);
      default:
        return false;
    }
  }

  /// 즐겨찾기 토글
  Future<void> toggle(FavoritesData data, String type, String value) async {
    final exists = isFavorite(data, type, value);
    if (exists) {
      await AppDatabase.deleteFavorite(type, value);
    } else {
      await AppDatabase.insertFavorite(type, value);
    }
  }

  /// 즐겨찾기 제거 (복수)
  Future<void> removeMultiple(List<int> ids) async {
    for (final id in ids) {
      await AppDatabase.deleteFavorite('gallery', id.toString());
    }
  }

  /// 내보내기
  Future<FavoritesData> export() async {
    return await getFavorites();
  }

  /// 가져오기
  Future<void> import(FavoritesData data) async {
    await AppDatabase.clearFavorites();

    final items = <Map<String, String>>[];
    for (final id in data.favoriteId) {
      items.add({'type': 'gallery', 'value': id.toString()});
    }
    for (final v in data.favoriteArtist) {
      items.add({'type': 'artist', 'value': v});
    }
    for (final v in data.favoriteTag) {
      final type = v.split(':').first;
      final value = v.split(':').last;
      items.add({'type': type, 'value': value});
    }
    for (final v in data.favoriteLanguage) {
      items.add({'type': 'language', 'value': v});
    }
    for (final v in data.favoriteGroup) {
      items.add({'type': 'group', 'value': v});
    }
    for (final v in data.favoriteParody) {
      items.add({'type': 'parody', 'value': v});
    }
    for (final v in data.favoriteCharacter) {
      items.add({'type': 'character', 'value': v});
    }
    await AppDatabase.batchInsertFavorites(items);
  }

  /// 캐시된 갤러리 조회
  Future<List<GalleryDetail>> getCachedGalleries(List<int> ids) async {
    final results = <GalleryDetail>[];
    final cachedMaps = await AppDatabase.queryCachedGalleries(ids);
    final cachedMap = {for (var item in cachedMaps) item['id'] as int: item};

    for (final id in ids) {
      if (cachedMap.containsKey(id)) {
        try {
          final json = jsonDecode(cachedMap[id]!['json'] as String);
          if (json['files'] != null && (json['files'] as List).isNotEmpty) {
            json['thumbnail'] = HitomiClient.buildThumbUrl(
              json['files'][0]['hash'],
            );
          }
          results.add(GalleryDetail.fromJson(json));
        } catch (_) {}
      }
    }
    return results;
  }

  /// 갤러리 캐싱
  Future<void> cacheGalleries(List<Map<String, dynamic>> details) async {
    final items = details
        .map((json) => {'id': json['id'], 'jsonString': jsonEncode(json)})
        .toList();
    await AppDatabase.cacheGalleries(items);
  }

  /// 전체 즐겨찾기 초기화
  Future<void> clearAll() async {
    await AppDatabase.clearFavorites();
  }
}
