import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../services/api_service.dart';

/// 검색 상태 관리 (GalleryState에서 분리)
/// 검색 쿼리, 자동완성 제안 관리
class SearchState extends ChangeNotifier {
  String _query = '';
  String get query => _query;

  List<TagSuggestion> _suggestions = [];
  List<TagSuggestion> get suggestions => _suggestions;

  bool _showSuggestions = false;
  bool get showSuggestions => _showSuggestions;

  void setQuery(String q) {
    _query = q;
    notifyListeners();

    if (q.isNotEmpty) {
      final lastToken = q.trim().split(' ').last;
      if (lastToken.isNotEmpty) {
        _fetchSuggestions(lastToken);
      } else {
        _clearSuggestions();
      }
    } else {
      _clearSuggestions();
    }
  }

  void _clearSuggestions() {
    _suggestions = [];
    _showSuggestions = false;
  }

  Future<void> _fetchSuggestions(String q) async {
    _suggestions = await ApiService.getSuggestions(q);
    if (_suggestions.isNotEmpty) _showSuggestions = true;
    notifyListeners();
  }

  void setShowSuggestions(bool v) {
    _showSuggestions = v;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _suggestions = [];
    _showSuggestions = false;
    notifyListeners();
  }
}
