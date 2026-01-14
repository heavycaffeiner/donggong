/// 순수 SQLite 데이터베이스 연산
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'donggong.db');

    _db = await openDatabase(
      path,
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS gallery_cache (id INTEGER PRIMARY KEY, json TEXT, timestamp INTEGER)',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS recent_searches (query TEXT PRIMARY KEY, timestamp INTEGER)',
          );
        }
      },
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS favorites (type TEXT, value TEXT, PRIMARY KEY(type, value))',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS recent_viewed (id INTEGER PRIMARY KEY, timestamp INTEGER)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS gallery_cache (id INTEGER PRIMARY KEY, json TEXT, timestamp INTEGER)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS recent_searches (query TEXT PRIMARY KEY, timestamp INTEGER)',
        );
      },
    );
  }

  static Database get db {
    if (_db == null) {
      throw StateError(
        'Database not initialized. Call AppDatabase.init() first.',
      );
    }
    return _db!;
  }

  // ─── Settings ───
  static Future<List<Map<String, dynamic>>> querySettings() async {
    return await db.query('settings');
  }

  static Future<void> upsertSetting(String key, String value) async {
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── Recent Viewed ───
  static Future<List<Map<String, dynamic>>> queryRecentViewed({
    int limit = 50,
  }) async {
    return await db.query(
      'recent_viewed',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  static Future<void> upsertRecentViewed(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('recent_viewed', {
      'id': id,
      'timestamp': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // Cleanup: keep top 50
    await db.rawDelete(
      'DELETE FROM recent_viewed WHERE id NOT IN (SELECT id FROM recent_viewed ORDER BY timestamp DESC LIMIT 50)',
    );
  }

  static Future<void> deleteRecentViewed(int id) async {
    await db.delete('recent_viewed', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Favorites ───
  static Future<List<Map<String, dynamic>>> queryFavorites() async {
    return await db.query('favorites');
  }

  static Future<void> insertFavorite(String type, String value) async {
    await db.insert('favorites', {
      'type': type,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deleteFavorite(String type, String value) async {
    await db.delete(
      'favorites',
      where: 'type = ? AND value = ?',
      whereArgs: [type, value],
    );
  }

  static Future<void> clearFavorites() async {
    await db.delete('favorites');
  }

  static Future<void> batchInsertFavorites(
    List<Map<String, String>> items,
  ) async {
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'favorites',
        item,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // ─── Gallery Cache ───
  static Future<List<Map<String, dynamic>>> queryCachedGalleries(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return [];

    if (ids.length > 900) {
      final results = <Map<String, dynamic>>[];
      for (var i = 0; i < ids.length; i += 500) {
        final end = (i + 500 < ids.length) ? i + 500 : ids.length;
        final chunk = ids.sublist(i, end);
        final res = await db.query(
          'gallery_cache',
          where: 'id IN (${chunk.join(',')})',
        );
        results.addAll(res);
      }
      return results;
    }

    return await db.query('gallery_cache', where: 'id IN (${ids.join(',')})');
  }

  static Future<void> cacheGalleries(List<Map<String, dynamic>> items) async {
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final json in items) {
      batch.insert('gallery_cache', {
        'id': json['id'],
        'json': json['jsonString'],
        'timestamp': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ─── Recent Searches ───
  static Future<List<String>> queryRecentSearches({int limit = 20}) async {
    final rows = await db.query(
      'recent_searches',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map((e) => e['query'] as String).toList();
  }

  static Future<void> upsertRecentSearch(String query) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('recent_searches', {
      'query': query,
      'timestamp': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Keep top 20
    await db.rawDelete(
      'DELETE FROM recent_searches WHERE query NOT IN (SELECT query FROM recent_searches ORDER BY timestamp DESC LIMIT 20)',
    );
  }

  static Future<void> deleteRecentSearch(String query) async {
    await db.delete('recent_searches', where: 'query = ?', whereArgs: [query]);
  }

  static Future<void> clearRecentSearches() async {
    await db.delete('recent_searches');
  }
}
