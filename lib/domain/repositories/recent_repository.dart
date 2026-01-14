/// 최근 본 항목 Repository
library;

import '../../data/data.dart';

class RecentRepository {
  /// 최근 본 ID 목록 조회
  Future<List<int>> getRecentIds() async {
    try {
      final rows = await AppDatabase.queryRecentViewed();
      return rows.map((row) => row['id'] as int).toList();
    } catch (_) {
      return [];
    }
  }

  /// 최근 본 항목 추가
  Future<void> addRecent(int id) async {
    await AppDatabase.upsertRecentViewed(id);
  }

  /// 최근 본 항목 제거
  Future<void> removeRecent(int id) async {
    await AppDatabase.deleteRecentViewed(id);
  }
}
