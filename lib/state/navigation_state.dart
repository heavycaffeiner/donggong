import 'package:flutter/foundation.dart';
import '../models/types.dart' show CustomScreen;

class NavigationState extends ChangeNotifier {
  CustomScreen _screen = CustomScreen.home;
  CustomScreen get screen => _screen;

  CustomScreen _lastTab = CustomScreen.home;
  CustomScreen? _previousScreen;
  CustomScreen? get previousScreen => _previousScreen;

  void setScreen(CustomScreen s) {
    _previousScreen = _screen;
    if (s != CustomScreen.reader) {
      _lastTab = s;
    }
    _screen = s;
    notifyListeners();
  }

  void closeReader() => setScreen(_lastTab);
}
