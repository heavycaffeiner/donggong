/// 최근 검색어 Repository
library;

import '../../data/data.dart';

class RecentSearchRepository {
  /// 최근 검색어 목록 조회
  Future<List<String>> getRecentSearches() async {
    try {
      return await AppDatabase.queryRecentSearches();
    } catch (_) {
      return [];
    }
  }

  /// 최근 검색어 추가
  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    await AppDatabase.upsertRecentSearch(query.trim());
  }

  /// 최근 검색어 삭제
  Future<void> removeRecentSearch(String query) async {
    await AppDatabase.deleteRecentSearch(query);
  }

  /// 최근 검색어 전체 삭제
  Future<void> clearRecentSearches() async {
    await AppDatabase.clearRecentSearches();
  }
}
