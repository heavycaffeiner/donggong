import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/types.dart';

class DbService {
  static Database? _db;

  static Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'favorites.db');

    _db = await openDatabase(
      path,
      version: 2, // Version bumped for cache table
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS gallery_cache (id INTEGER PRIMARY KEY, json TEXT, timestamp INTEGER)',
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
      },
    );
  }

  // Settings
  static Future<SettingsData> getSettings() async {
    final db = _db;
    if (db == null) return SettingsData.defaults();

    try {
      final res = await db.query('settings');
      final settings = SettingsData.defaults();

      for (final row in res) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        if (key == 'defaultLanguage') settings.defaultLanguage = value;
        if (key == 'theme') settings.theme = value;
      }
      return settings;
    } catch (e) {
      return SettingsData.defaults();
    }
  }

  static Future<void> setSetting(String key, String value) async {
    final db = _db;
    if (db == null) return;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Recent Viewed
  static Future<List<int>> getRecentViewed() async {
    final db = _db;
    if (db == null) return [];

    try {
      final res = await db.query(
        'recent_viewed',
        orderBy: 'timestamp DESC',
        limit: 50,
      );
      return res.map((row) => row['id'] as int).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addRecentViewed(int id) async {
    final db = _db;
    if (db == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('recent_viewed', {
      'id': id,
      'timestamp': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Cleanup old items (keep top 50)
    // SQFlite doesn't support complex nested delete easily in one go compatible with all sqlite versions,
    // but we can just run a delete where id not in top 50.
    // Equivalent: DELETE FROM recent_viewed WHERE id NOT IN (SELECT id FROM recent_viewed ORDER BY timestamp DESC LIMIT 50)
    await db.rawDelete(
      'DELETE FROM recent_viewed WHERE id NOT IN (SELECT id FROM recent_viewed ORDER BY timestamp DESC LIMIT 50)',
    );
  }

  static Future<void> removeRecent(int id) async {
    final db = _db;
    if (db == null) return;
    await db.delete('recent_viewed', where: 'id = ?', whereArgs: [id]);
  }

  // Favorites
  static Future<FavoritesData> getFavorites() async {
    final data = FavoritesData.empty();
    final db = _db;
    if (db == null) return data;

    try {
      final res = await db.query('favorites');
      for (final row in res) {
        final type = row['type'] as String;
        final value = row['value'] as String;

        if (type == 'gallery') {
          data.favoriteId.add(int.parse(value));
        } else if (type == 'artist') {
          data.favoriteArtist.add(value);
        } else if (type == 'tag') {
          data.favoriteTag.add(value);
        } else if (type == 'language') {
          data.favoriteLanguage.add(value);
        }
      }
    } catch (_) {
      // Silently ignore favorites loading errors
    }
    return data;
  }

  static Future<void> addFavorite(String type, String value) async {
    final db = _db;
    if (db == null) return;
    await db.insert('favorites', {
      'type': type,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> removeFavorite(String type, String value) async {
    final db = _db;
    if (db == null) return;
    await db.delete(
      'favorites',
      where: 'type = ? AND value = ?',
      whereArgs: [type, value],
    );
  }

  static Future<FavoritesData> export() async {
    return await getFavorites();
  }

  static Future<void> import(FavoritesData data) async {
    final db = _db;
    if (db == null) return;

    await db.transaction((txn) async {
      await txn.delete('favorites');

      final batch = txn.batch();
      for (final id in data.favoriteId) {
        batch.insert('favorites', {
          'type': 'gallery',
          'value': id.toString(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final v in data.favoriteArtist) {
        batch.insert('favorites', {
          'type': 'artist',
          'value': v,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final v in data.favoriteTag) {
        batch.insert('favorites', {
          'type': 'tag',
          'value': v,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final v in data.favoriteLanguage) {
        batch.insert('favorites', {
          'type': 'language',
          'value': v,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  // Cache
  static Future<List<Map<String, dynamic>>> getCachedGalleries(
    List<int> ids,
  ) async {
    final db = _db;
    if (db == null || ids.isEmpty) return [];

    try {
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

      final res = await db.query(
        'gallery_cache',
        where: 'id IN (${ids.join(',')})',
      );
      return res;
    } catch (_) {
      return [];
    }
  }

  static Future<void> cacheGalleries(List<Map<String, dynamic>> details) async {
    final db = _db;
    if (db == null) return;

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final json in details) {
      batch.insert('gallery_cache', {
        'id': json['id'],
        'json': jsonEncode(json),
        'timestamp': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> updateGalleryCache(Map<String, dynamic> json) async {
    final db = _db;
    if (db == null) return;

    await db.insert('gallery_cache', {
      'id': json['id'],
      'json': jsonEncode(json),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
