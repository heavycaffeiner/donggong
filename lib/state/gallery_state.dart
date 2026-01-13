import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../services/api_service.dart';

/// 갤러리 목록 상태 관리
class GalleryState extends ChangeNotifier {
  List<GalleryDetail> _galleries = [];
  List<GalleryDetail> get galleries => _galleries;

  bool _loading = false;
  bool get loading => _loading;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  int _page = 1;
  String _lastQuery = '';
  String _lastLang = '';

  void clear() {
    _galleries = [];
    _page = 1;
    notifyListeners();
  }

  Future<void> loadGalleries({
    bool reset = false,
    String defaultLang = 'korean',
    String query = '',
    bool force = false,
  }) async {
    if (_loading) return;

    if (reset &&
        !force &&
        _lastQuery == query &&
        _lastLang == defaultLang &&
        _galleries.isNotEmpty) {
      return;
    }

    if (reset) {
      _galleries = [];
      _lastQuery = query;
      _lastLang = defaultLang;
    }

    _loading = true;
    notifyListeners();

    try {
      final p = reset ? 1 : _page;

      final list = query.isNotEmpty
          ? await ApiService.search(query, page: p, defaultLang: defaultLang)
          : await ApiService.getList(page: p, lang: defaultLang);

      if (reset) {
        _galleries = list;
        _page = 2;
      } else {
        final existingIds = _galleries.map((g) => g.id).toSet();
        final newItems = list
            .where((g) => !existingIds.contains(g.id))
            .toList();
        _galleries.addAll(newItems);
        _page = p + 1;
      }
    } catch (e) {
      debugPrint('Error loading galleries: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String defaultLang, {String query = ''}) async {
    _refreshing = true;
    notifyListeners();
    await loadGalleries(
      reset: true,
      defaultLang: defaultLang,
      query: query,
      force: true,
    );
    _refreshing = false;
    notifyListeners();
  }
}
