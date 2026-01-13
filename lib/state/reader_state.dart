import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

/// 리더 상태 관리
/// Repository 레이어 없이 직접 ApiService/DbService 호출
class ReaderState extends ChangeNotifier {
  GalleryDetail? _gallery;
  GalleryDetail? get gallery => _gallery;

  bool _loading = false;
  bool get loading => _loading;

  bool _controlsVisible = true;
  bool get controlsVisible => _controlsVisible;

  void toggleControls() {
    _controlsVisible = !_controlsVisible;
    notifyListeners();
  }

  void setControls(bool visible) {
    _controlsVisible = visible;
    notifyListeners();
  }

  Future<void> loadGallery(int id) async {
    _loading = true;
    _gallery = null;
    notifyListeners();

    try {
      _gallery = await ApiService.getReaderCached(id);
      await DbService.addRecentViewed(id);
    } catch (e) {
      debugPrint('Error loading reader: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _gallery = null;
    notifyListeners();
  }
}
