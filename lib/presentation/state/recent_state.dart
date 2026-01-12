import 'package:flutter/foundation.dart';
import '../../models/types.dart';
import '../../services/api_service.dart';
import '../../services/db_service.dart';

class RecentState extends ChangeNotifier {
  List<GalleryItem> _recents = [];
  List<GalleryItem> get recents => _recents;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadRecents() async {
    _loading = true;
    notifyListeners();
    try {
      final ids = await DbService.getRecentViewed();
      if (ids.isEmpty) {
        _recents = [];
      } else {
        // IDs are stored in order, so latest should be last usually?
        // DbService.getRecentViewed() implementation likely returns them in some order.
        // Assuming we want reversed (newest first).
        // Let's check logic: _galleries = details...reversed.toList();

        final details = await Future.wait(
          ids.map((id) => ApiService.getDetailCached(id)),
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
    notifyListeners();
  }
}
