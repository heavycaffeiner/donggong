import 'package:flutter/foundation.dart';
import '../../models/types.dart';
import '../../services/api_service.dart';
import '../../services/db_service.dart';

class RecentState extends ChangeNotifier {
  List<GalleryDetail> _recents = [];
  List<GalleryDetail> get recents => _recents;

  bool _loading = false;
  bool get loading => _loading;

  List<int> _cachedIds = [];

  Future<void> loadRecents() async {
    final dbIds = await DbService.getRecentViewed();

    // Compare with cached IDs - skip if unchanged
    if (_listEquals(dbIds, _cachedIds)) {
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      _cachedIds = dbIds;
      if (dbIds.isEmpty) {
        _recents = [];
      } else {
        final details = await Future.wait(
          dbIds.map((id) => ApiService.getDetailCached(id)),
        );
        _recents = details.where((d) => d.id != 0).toList();
      }
    } catch (e) {
      debugPrint('Error loading recents: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> removeRecent(int id) async {
    try {
      await DbService.removeRecent(id);
      _recents.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing recent: $e');
    }
  }

  void clear() {
    _recents = [];
    _cachedIds = [];
    notifyListeners();
  }
}
