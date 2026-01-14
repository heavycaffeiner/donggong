import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/domain.dart';

part 'settings_provider.g.dart';

@riverpod
SettingsRepository settingsRepository(Ref ref) => SettingsRepository();

@riverpod
class Settings extends _$Settings {
  @override
  Future<SettingsData> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    return await repo.getSettings();
  }

  Future<void> setSetting(String key, String value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setSetting(key, value);

    final current = state.value ?? SettingsData.defaults();
    if (key == 'defaultLanguage') current.defaultLanguage = value;
    if (key == 'theme') current.theme = value;
    state = AsyncValue.data(current);
  }
}
