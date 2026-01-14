import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/domain.dart';

part 'recent_search_provider.g.dart';

@riverpod
RecentSearchRepository recentSearchRepository(Ref ref) =>
    RecentSearchRepository();

@Riverpod(keepAlive: true)
class RecentSearch extends _$RecentSearch {
  @override
  Future<List<String>> build() async {
    return _loadRecentSearches();
  }

  Future<List<String>> _loadRecentSearches() async {
    final repo = ref.read(recentSearchRepositoryProvider);
    return await repo.getRecentSearches();
  }

  Future<void> add(String query) async {
    final repo = ref.read(recentSearchRepositoryProvider);
    await repo.addRecentSearch(query);
    ref.invalidateSelf();
  }

  Future<void> remove(String query) async {
    final repo = ref.read(recentSearchRepositoryProvider);
    await repo.removeRecentSearch(query);
    ref.invalidateSelf();
  }

  Future<void> clear() async {
    final repo = ref.read(recentSearchRepositoryProvider);
    await repo.clearRecentSearches();
    ref.invalidateSelf();
  }
}
