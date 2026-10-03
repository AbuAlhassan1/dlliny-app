import 'dart:convert';
import 'dart:developer';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppCacheRepository {
  static const _dbName = 'hangout_app_cache.db';
  static const _schemaVersion = 1;
  static const _table = 'kv_cache';

  Database? _db;
  Future<Database>? _opening;

  Future<Database> _open() {
    if (_db != null) return Future.value(_db!);
    return _opening ??= _openImpl();
  }

  Future<Database> _openImpl() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_dbName';
    final db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            key TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<dynamic> read(String key) async {
    try {
      final db = await _open();
      final rows = await db.query(
        _table,
        columns: ['json'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['json'] as String);
    } catch (e, s) {
      log('AppCache read failed for "$key"', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> write(String key, Object? value) async {
    try {
      final db = await _open();
      await db.insert(
        _table,
        {
          'key': key,
          'json': jsonEncode(value),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, s) {
      log('AppCache write failed for "$key"', error: e, stackTrace: s);
    }
  }

  Future<void> remove(String key) async {
    try {
      final db = await _open();
      await db.delete(_table, where: 'key = ?', whereArgs: [key]);
    } catch (e, s) {
      log('AppCache remove failed for "$key"', error: e, stackTrace: s);
    }
  }

  Future<void> clear() async {
    try {
      final db = await _open();
      await db.delete(_table);
    } catch (e, s) {
      log('AppCache clear failed', error: e, stackTrace: s);
    }
  }
}

abstract class HubCacheKeys {
  static const weeklyVenues = 'hub.weekly_venues';
  static const intents = 'hub.intents';
  static const awaitingReview = 'hub.awaiting_review';

  static const showcaseSeen = 'hub.showcase_seen';
}

abstract class AppCacheKeys {
  static const myProfile = 'user.profile';

  static const challenges = 'challenges.list';
}
