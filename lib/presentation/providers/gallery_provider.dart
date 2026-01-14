import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data.dart';
import 'search_provider.dart';

part 'gallery_provider.g.dart';

class GalleryState {
  final List<GalleryDetail> galleries;
  final bool loading;
  final bool refreshing;

  const GalleryState({
    this.galleries = const [],
    this.loading = false,
    this.refreshing = false,
  });

  GalleryState copyWith({
    List<GalleryDetail>? galleries,
    bool? loading,
    bool? refreshing,
  }) => GalleryState(
    galleries: galleries ?? this.galleries,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
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
    if (state.loading) return;

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

      final list = query.isNotEmpty
          ? await repo.search(query, page: p, defaultLang: defaultLang)
          : await repo.getList(page: p, lang: defaultLang);

      if (reset) {
        state = state.copyWith(galleries: list, loading: false);
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
}
