import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data.dart';
import '../../domain/domain.dart';
import 'search_provider.dart';

part 'favorite_provider.g.dart';

@riverpod
FavoriteRepository favoriteRepository(Ref ref) => FavoriteRepository();

/// 앱 시작 시 자동으로 FavoritesData를 로드하는 provider
@riverpod
Future<FavoritesData> favoriteData(Ref ref) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return await repo.getFavorites();
}

class FavoriteState {
  final List<GalleryDetail> favorites;
  final List<GalleryDetail> allLoaded;
  final FavoritesData favoritesData;
  final bool loading;
  final String query;

  const FavoriteState({
    this.favorites = const [],
    this.allLoaded = const [],
    required this.favoritesData,
    this.loading = false,
    this.query = '',
  });

  factory FavoriteState.initial() =>
      FavoriteState(favoritesData: FavoritesData.empty());

  FavoriteState copyWith({
    List<GalleryDetail>? favorites,
    List<GalleryDetail>? allLoaded,
    FavoritesData? favoritesData,
    bool? loading,
    String? query,
  }) => FavoriteState(
    favorites: favorites ?? this.favorites,
    allLoaded: allLoaded ?? this.allLoaded,
    favoritesData: favoritesData ?? this.favoritesData,
    loading: loading ?? this.loading,
    query: query ?? this.query,
  );
}

@Riverpod(keepAlive: true)
class Favorite extends _$Favorite {
  List<int> _cachedIds = [];

  @override
  FavoriteState build() {
    // 초기화 시 DB에서 데이터 로드
    _initializeFavorites();
    return FavoriteState.initial();
  }

  Future<void> _initializeFavorites() async {
    final favRepo = ref.read(favoriteRepositoryProvider);
    final data = await favRepo.getFavorites();
    state = state.copyWith(favoritesData: data);
  }

  Future<void> loadFavorites({String? query}) async {
    final targetQuery = query ?? state.query;
    final favRepo = ref.read(favoriteRepositoryProvider);
    final currentData = await favRepo.getFavorites();
    final dbIds = currentData.favoriteId.toList();

    if (_listEquals(dbIds, _cachedIds) &&
        targetQuery == state.query &&
        state.favorites.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      loading: true,
      favorites: [],
      allLoaded: [],
      query: query ?? state.query,
    );
    _cachedIds = dbIds;

    try {
      final ids = currentData.favoriteId.reversed.toList();
      if (ids.isEmpty) {
        state = state.copyWith(loading: false, favoritesData: currentData);
        return;
      }

      final galleryRepo = ref.read(galleryRepositoryProvider);
      final allLoaded = <GalleryDetail>[];
      final missingIds = <int>[];

      // 캐시에서 로드
      final cached = await favRepo.getCachedGalleries(ids);
      final cachedMap = {for (var g in cached) g.id: g};

      for (final id in ids) {
        if (cachedMap.containsKey(id)) {
          allLoaded.add(cachedMap[id]!);
        } else {
          missingIds.add(id);
        }
      }

      _updateFilteredList(allLoaded, targetQuery);
      state = state.copyWith(favoritesData: currentData, allLoaded: allLoaded);

      // 누락된 항목 fetch
      for (var i = 0; i < missingIds.length; i += 10) {
        final end = (i + 10 < missingIds.length) ? i + 10 : missingIds.length;
        final batchIds = missingIds.sublist(i, end);

        final results = await Future.wait(
          batchIds.map((id) async {
            try {
              return await galleryRepo.getDetailWithJson(id);
            } catch (_) {
              return null;
            }
          }),
        );

        final mapsToCache = <Map<String, dynamic>>[];
        for (final result in results) {
          if (result != null) {
            final detail = result.$1;
            final json = result.$2;
            if (detail.id != 0) {
              allLoaded.add(detail);
              json['id'] = detail.id;
              mapsToCache.add(json);
            }
          }
        }

        _updateFilteredList(allLoaded, targetQuery);
        state = state.copyWith(allLoaded: List.from(allLoaded));

        if (mapsToCache.isNotEmpty) {
          await favRepo.cacheGalleries(mapsToCache);
        }
      }

      state = state.copyWith(loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void _updateFilteredList(List<GalleryDetail> allLoaded, String query) {
    final filtered = query.isEmpty
        ? allLoaded
        : allLoaded.where((item) => item.matches(query)).toList();
    state = state.copyWith(favorites: filtered);
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> refreshFavorites({String? query}) async {
    _cachedIds = [];
    await loadFavorites(query: query);
  }

  Future<void> toggleFavorite(String type, String value) async {
    final repo = ref.read(favoriteRepositoryProvider);
    await repo.toggle(state.favoritesData, type, value);
    _cachedIds = [];
    // favoriteDataProvider를 무효화하여 즉시 갱신
    ref.invalidate(favoriteDataProvider);
    await loadFavorites();
  }

  bool isFavorite(String type, dynamic value) {
    final repo = ref.read(favoriteRepositoryProvider);
    return repo.isFavorite(state.favoritesData, type, value);
  }

  Future<List<int>> validateFavorites() async {
    final invalidIds = <int>[];
    final galleryRepo = ref.read(galleryRepositoryProvider);
    for (final id in state.favoritesData.favoriteId) {
      try {
        await galleryRepo.getDetail(id);
      } catch (_) {
        invalidIds.add(id);
      }
    }
    return invalidIds;
  }

  Future<void> removeFavorites(List<int> ids) async {
    final repo = ref.read(favoriteRepositoryProvider);
    await repo.removeMultiple(ids);
    _cachedIds = [];
    await loadFavorites();
  }

  Future<void> clearAllFavorites() async {
    final repo = ref.read(favoriteRepositoryProvider);
    await repo.clearAll();
    _cachedIds = [];
    state = FavoriteState.initial();
    ref.invalidate(favoriteDataProvider);
  }
}
