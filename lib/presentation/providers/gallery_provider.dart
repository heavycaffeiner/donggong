import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data.dart';
import 'search_provider.dart';

part 'gallery_provider.g.dart';

class GalleryState {
  final List<GalleryDetail> galleries;
  final bool loading;
  final bool refreshing;
  final int totalCount;

  const GalleryState({
    this.galleries = const [],
    this.loading = false,
    this.refreshing = false,
    this.totalCount = 0,
  });

  GalleryState copyWith({
    List<GalleryDetail>? galleries,
    bool? loading,
    bool? refreshing,
    int? totalCount,
  }) => GalleryState(
    galleries: galleries ?? this.galleries,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    totalCount: totalCount ?? this.totalCount,
  );
}

@riverpod
class Gallery extends _$Gallery {
  int _page = 1;
  String _lastQuery = '';
  String _lastLang = '';

  @override
  GalleryState build() => const GalleryState();

  Future<void> loadGalleries({
    bool reset = false,
    String defaultLang = 'korean',
    String query = '',
    bool force = false,
  }) async {
    // force가 아니면 로딩 중 중복 호출 방지
    if (!force && state.loading) return;

    if (reset &&
        !force &&
        _lastQuery == query &&
        _lastLang == defaultLang &&
        state.galleries.isNotEmpty) {
      return;
    }

    var galleries = state.galleries;
    if (reset) {
      galleries = [];
      _lastQuery = query;
      _lastLang = defaultLang;
    }

    state = state.copyWith(loading: true, galleries: galleries);

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final p = reset ? 1 : _page;

      List<GalleryDetail> list;
      int totalCount = state.totalCount;

      if (query.isNotEmpty) {
        final result = await repo.search(
          query,
          page: p,
          defaultLang: defaultLang,
        );
        list = result.$1;
        totalCount = result.$2;
      } else {
        // getListWithTotal로 리스트와 전체 갤러리 수를 함께 가져옴
        final result = await repo.getListWithTotal(page: p, lang: defaultLang);
        list = result.$1;
        // 항상 최신 totalCount로 업데이트
        totalCount = result.$2;
      }

      if (reset) {
        // 비동기 작업 후 현재 쿼리와 요청 쿼리가 다르면 무시 (사용자가 검색 취소/변경함)
        final currentQuery = ref.read(searchProvider).query;
        if (currentQuery != query) {
          state = state.copyWith(loading: false);
          return;
        }

        state = state.copyWith(
          galleries: list,
          loading: false,
          totalCount: totalCount,
        );
        _page = 2;
      } else {
        final existingIds = state.galleries.map((g) => g.id).toSet();
        final newItems = list
            .where((g) => !existingIds.contains(g.id))
            .toList();
        state = state.copyWith(
          galleries: [...state.galleries, ...newItems],
          loading: false,
        );
        _page = p + 1;
      }
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> refresh(String defaultLang, {String query = ''}) async {
    state = state.copyWith(refreshing: true);
    await loadGalleries(
      reset: true,
      defaultLang: defaultLang,
      query: query,
      force: true,
    );
    state = state.copyWith(refreshing: false);
  }

  void clear() {
    _page = 1;
    state = const GalleryState();
  }

  /// 특정 페이지만 로드 (페이지네이션 모드용)
  Future<void> loadGalleriesPage({
    required int page,
    String defaultLang = 'korean',
    String query = '',
  }) async {
    // 페이지 이동은 로딩 중이면 무시
    if (state.loading) return;

    state = state.copyWith(loading: true, galleries: []);

    try {
      final repo = ref.read(galleryRepositoryProvider);

      List<GalleryDetail> list;
      int totalCount = state.totalCount;

      if (query.isNotEmpty) {
        final result = await repo.search(
          query,
          page: page,
          defaultLang: defaultLang,
        );
        list = result.$1;
        totalCount = result.$2;
      } else {
        // getListWithTotal로 리스트와 전체 갤러리 수를 함께 가져옴
        final result = await repo.getListWithTotal(
          page: page,
          lang: defaultLang,
        );
        list = result.$1;
        // 항상 최신 totalCount로 업데이트
        totalCount = result.$2;
      }

      // 비동기 작업 후 현재 쿼리와 일치하는지 확인
      final currentQuery = ref.read(searchProvider).query;
      if (currentQuery != query) {
        state = state.copyWith(loading: false);
        return;
      }

      state = state.copyWith(
        galleries: list,
        loading: false,
        totalCount: totalCount,
      );
      _page = page;
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }
}
