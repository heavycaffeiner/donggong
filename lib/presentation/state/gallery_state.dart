import 'package:flutter/foundation.dart';
import '../../models/types.dart';
import '../../services/api_service.dart';

/// 갤러리 목록 상태 관리
/// 검색 로직은 SearchState로 분리됨
class GalleryState extends ChangeNotifier {
  List<GalleryItem> _galleries = [];
  List<GalleryItem> get galleries => _galleries;

  bool _loading = false;
  bool get loading => _loading;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  int _page = 1;

  void clear() {
    _galleries = [];
    notifyListeners();
  }

  Future<void> loadGalleries({
    bool reset = false,
    String defaultLang = 'korean',
    String query = '',
  }) async {
    if (_loading) return;
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
        _galleries.addAll(list);
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
    await loadGalleries(reset: true, defaultLang: defaultLang, query: query);
    _refreshing = false;
    notifyListeners();
  }
}
