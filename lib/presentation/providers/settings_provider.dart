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

    // copyWith로 새 인스턴스 생성하여 Riverpod 변경 감지 보장
    final updated = switch (key) {
      'defaultLanguage' => current.copyWith(defaultLanguage: value),
      'theme' => current.copyWith(theme: value),
      'listingMode' => current.copyWith(listingMode: value),
      'readerMode' => current.copyWith(readerMode: value),
      'cardViewMode' => current.copyWith(cardViewMode: value),
      _ => current,
    };

    state = AsyncValue.data(updated);
  }
}
