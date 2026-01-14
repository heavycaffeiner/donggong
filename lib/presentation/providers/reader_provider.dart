import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data.dart';
import '../../domain/domain.dart';
import 'search_provider.dart';

part 'reader_provider.g.dart';

@riverpod
RecentRepository recentRepository(Ref ref) => RecentRepository();

@Riverpod(keepAlive: true)
class Reader extends _$Reader {
  @override
  Future<GalleryDetail?> build() async => null;

  Future<void> loadGallery(int id) async {
    state = const AsyncValue.loading();
    try {
      final galleryRepo = ref.read(galleryRepositoryProvider);
      final recentRepo = ref.read(recentRepositoryProvider);

      final detail = await galleryRepo.getReader(id);
      await recentRepo.addRecent(id);
      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

@riverpod
class ReaderControls extends _$ReaderControls {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void set(bool v) => state = v;
}
