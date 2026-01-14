import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data.dart';
import 'reader_provider.dart';
import 'search_provider.dart';

part 'recent_provider.g.dart';

class RecentState {
  final List<GalleryDetail> recents;
  final bool loading;

  const RecentState({this.recents = const [], this.loading = false});

  RecentState copyWith({List<GalleryDetail>? recents, bool? loading}) =>
      RecentState(
        recents: recents ?? this.recents,
        loading: loading ?? this.loading,
      );
}

@riverpod
class Recent extends _$Recent {
  List<int> _cachedIds = [];

  @override
  RecentState build() => const RecentState();

  Future<void> loadRecents() async {
    final repo = ref.read(recentRepositoryProvider);
    final dbIds = await repo.getRecentIds();

    if (_listEquals(dbIds, _cachedIds)) return;

    state = state.copyWith(loading: true);
    _cachedIds = dbIds;

    try {
      if (dbIds.isEmpty) {
        state = const RecentState();
        return;
      }

      final galleryRepo = ref.read(galleryRepositoryProvider);
      final details = await Future.wait(
        dbIds.map((id) => galleryRepo.getDetail(id)),
      );
      state = RecentState(recents: details.where((d) => d.id != 0).toList());
    } catch (_) {
      state = state.copyWith(loading: false);
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
    final repo = ref.read(recentRepositoryProvider);
    await repo.removeRecent(id);
    state = state.copyWith(
      recents: state.recents.where((item) => item.id != id).toList(),
    );
  }

  void clear() {
    _cachedIds = [];
    state = const RecentState();
  }
}
