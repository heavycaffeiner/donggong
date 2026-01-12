import 'package:flutter/foundation.dart';
import '../../models/types.dart' show CustomScreen;

class NavigationState extends ChangeNotifier {
  CustomScreen _screen = CustomScreen.home;
  CustomScreen get screen => _screen;

  CustomScreen _lastTab = CustomScreen.home;

  void setScreen(CustomScreen s) {
    if (s != CustomScreen.reader) {
      _lastTab = s;
    }
    _screen = s;
    notifyListeners();
  }

  void closeReader() {
    setScreen(_lastTab);
  }
}
