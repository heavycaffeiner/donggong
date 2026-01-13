import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/types.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

/// 즐겨찾기 상태 관리
class FavoriteState extends ChangeNotifier {
  List<GalleryDetail> _favorites = [];
  List<GalleryDetail> get favorites => _favorites;

  List<GalleryDetail> _allLoaded = [];
  FavoritesData _favoritesData = FavoritesData.empty();
  FavoritesData get favoritesData => _favoritesData;

  bool _loading = false;
  bool get loading => _loading;

  String _query = '';
  List<int> _cachedIds = [];

  void clear() {
    _favorites = [];
    _allLoaded = [];
    _cachedIds = [];
    notifyListeners();
  }

  Future<void> loadFavorites({String? query}) async {
    final targetQuery = query ?? _query;
    final currentData = await DbService.getFavorites();
    final dbIds = currentData.favoriteId.toList();

    // Compare with cached IDs - skip if unchanged and query is same
    if (_listEquals(dbIds, _cachedIds) &&
        targetQuery == _query &&
        _favorites.isNotEmpty) {
      return;
    }

    _favorites = [];
    _allLoaded = [];
    _loading = true;
    notifyListeners();

    if (query != null) _query = query;
    _cachedIds = dbIds;

    try {
      _favoritesData = currentData;
      final ids = _favoritesData.favoriteId.reversed.toList();

      if (ids.isEmpty) {
        _loading = false;
        notifyListeners();
        return;
      }

      // 1. 로컬 캐시에서 로드 (배치 단위)
      final missingIds = <int>[];

      for (var i = 0; i < ids.length; i += 50) {
        final end = (i + 50 < ids.length) ? i + 50 : ids.length;
        final chunkIds = ids.sublist(i, end);
        final cachedMaps = await DbService.getCachedGalleries(chunkIds);
        final cachedMap = {
          for (var item in cachedMaps) item['id'] as int: item,
        };

        for (final id in chunkIds) {
          if (cachedMap.containsKey(id)) {
            try {
              final json = jsonDecode(cachedMap[id]!['json'] as String);
              if (json['files'] != null && (json['files'] as List).isNotEmpty) {
                json['thumbnail'] = ApiService.buildThumbUrl(
                  json['files'][0]['hash'],
                );
              }
              _allLoaded.add(GalleryDetail.fromJson(json));
            } catch (_) {
              missingIds.add(id);
            }
          } else {
            missingIds.add(id);
          }
        }

        _updateFilteredList();
        notifyListeners();
        await Future.delayed(Duration.zero);
      }

      _loading = false;
      notifyListeners();

      // 2. 누락된 항목 백그라운드 fetch
      if (missingIds.isNotEmpty) {
        await _fetchAndCacheMissing(missingIds);
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndCacheMissing(List<int> ids) async {
    final mapsToCache = <Map<String, dynamic>>[];

    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final batchIds = ids.sublist(i, end);

      final results = await Future.wait(
        batchIds.map((id) async {
          try {
            return await ApiService.getDetailWithOriginalJson(id);
          } catch (_) {
            return null;
          }
        }),
      );

      for (final result in results) {
        if (result != null) {
          final detail = result.$1;
          final json = result.$2;
          if (detail.id != 0) {
            _allLoaded.add(detail);
            json['id'] = detail.id;
            mapsToCache.add(json);
          }
        }
      }

      _updateFilteredList();
      notifyListeners();

      if (mapsToCache.isNotEmpty) {
        await DbService.cacheGalleries(mapsToCache);
        mapsToCache.clear();
      }
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _updateFilteredList() {
    // GalleryDetail.matches() 사용
    _favorites = _query.isEmpty
        ? _allLoaded
        : _allLoaded.where((item) => item.matches(_query)).toList();
  }

  Future<void> refreshFavorites() async {
    _cachedIds = [];
    await loadFavorites();
  }

  Future<void> toggleFavorite(String type, String value) async {
    final data = await DbService.getFavorites();
    bool exists = false;

    if (type == 'gallery') {
      final id = int.tryParse(value);
      if (id != null) exists = data.favoriteId.contains(id);
    } else if (type == 'artist') {
      exists = data.favoriteArtist.contains(value);
    } else if (type == 'tag') {
      exists = data.favoriteTag.contains(value);
    } else if (type == 'language') {
      exists = data.favoriteLanguage.contains(value);
    }

    if (exists) {
      await DbService.removeFavorite(type, value);
    } else {
      await DbService.addFavorite(type, value);
    }

    _cachedIds = [];
    await loadFavorites();
  }

  bool isFavorite(String type, dynamic value) {
    switch (type) {
      case 'gallery':
        final id = int.tryParse(value.toString());
        return id != null && _favoritesData.favoriteId.contains(id);
      case 'artist':
        return _favoritesData.favoriteArtist.contains(value);
      case 'tag':
        return _favoritesData.favoriteTag.contains(value);
      case 'language':
        return _favoritesData.favoriteLanguage.contains(value);
      default:
        return false;
    }
  }

  Future<List<int>> validateFavorites() async {
    final invalidIds = <int>[];
    final idsToCheck = List<int>.from(_favoritesData.favoriteId);

    for (final id in idsToCheck) {
      try {
        await ApiService.getDetail(id);
      } catch (_) {
        invalidIds.add(id);
      }
    }
    return invalidIds;
  }

  Future<void> removeFavorites(List<int> ids) async {
    for (final id in ids) {
      await DbService.removeFavorite('gallery', id.toString());
    }
    _cachedIds = [];
    await loadFavorites();
  }
}
