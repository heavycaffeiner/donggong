import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../shared/shared.dart';

part 'navigation_provider.g.dart';

@riverpod
class Navigation extends _$Navigation {
  CustomScreen _lastTab = CustomScreen.home;
  CustomScreen? _previousScreen;
  CustomScreen? get previousScreen => _previousScreen;

  @override
  CustomScreen build() => CustomScreen.home;

  void setScreen(CustomScreen s) {
    _previousScreen = state;
    if (s != CustomScreen.reader) _lastTab = s;
    state = s;
  }

  void closeReader() => setScreen(_lastTab);
}
