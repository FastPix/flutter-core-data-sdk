import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../logger/metrics_logger.dart';

/// Disk-backed persistence for the event queue. Mirrors Android's Room-backed
/// EventStore: every dispatched event is inserted on enqueue and deleted on a
/// successful POST. On SDK init, pending rows are reloaded into the in-memory
/// queue so events survive process death.
///
/// Single-table schema (`events`):
///   - id          INTEGER PK AUTOINCREMENT  (FIFO ordering by row id)
///   - payload     TEXT                       (jsonEncoded event map)
///   - created_at  INTEGER                    (millisSinceEpoch — for TTL)
///
/// One persisted row corresponds to one in-memory event. The dispatcher tracks
/// the row id alongside the event so it can delete by id after a successful
/// upload.
class EventStore {
  EventStore._();

  static final EventStore instance = EventStore._();

  static const String _tableName = 'events';
  static const String _dbFileName = 'fastpix_event_store.db';
  static const int _schemaVersion = 1;

  /// Hard cap mirroring Android's legacy SharedPrefs cap. When the DB grows
  /// past this we drop the oldest rows on insert.
  static const int defaultMaxRows = 500;
  int maxRows = defaultMaxRows;

  Database? _db;
  Completer<void>? _initCompleter;

  /// Awaitable that resolves once the DB is open and ready. Safe to await
  /// repeatedly. Errors during init disable persistence (calls become no-ops)
  /// rather than failing the SDK.
  Future<void> get ready {
    final existing = _initCompleter;
    if (existing != null) return existing.future;
    final c = Completer<void>();
    _initCompleter = c;
    _open().then((_) => c.complete()).catchError((Object e, StackTrace s) {
      MetricsLogger.logError('EventStore init failed; persistence disabled', e);
      c.complete();
    });
    return c.future;
  }

  Future<void> _open() async {
    final dbPath = p.join(await getDatabasesPath(), _dbFileName);
    _db = await openDatabase(
      dbPath,
      version: _schemaVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_${_tableName}_created_at ON $_tableName(created_at)');
      },
    );
  }

  /// Inserts one event, returning its row id. Returns `null` if persistence
  /// is unavailable (init failed) — caller can still queue in memory.
  Future<int?> insert(Map<String, dynamic> event) async {
    await ready;
    final db = _db;
    if (db == null) return null;
    try {
      final id = await db.insert(_tableName, {
        'payload': jsonEncode(event),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      await _enforceCap(db);
      return id;
    } catch (e) {
      MetricsLogger.logError('EventStore.insert failed', e);
      return null;
    }
  }

  /// Returns all stored events in FIFO (oldest-first) order. Used at SDK
  /// init to repopulate the in-memory queue.
  Future<List<StoredEvent>> loadAll() async {
    await ready;
    final db = _db;
    if (db == null) return const [];
    try {
      final rows =
          await db.query(_tableName, orderBy: 'id ASC');
      return rows
          .map((r) => StoredEvent(
                id: r['id'] as int,
                payload: jsonDecode(r['payload'] as String)
                    as Map<String, dynamic>,
                createdAtMs: r['created_at'] as int,
              ))
          .toList();
    } catch (e) {
      MetricsLogger.logError('EventStore.loadAll failed', e);
      return const [];
    }
  }

  /// Deletes a batch of rows by id. Called after a successful POST.
  Future<void> deleteByIds(Iterable<int> ids) async {
    await ready;
    final db = _db;
    if (db == null || ids.isEmpty) return;
    try {
      final list = ids.toList();
      final placeholders = List.filled(list.length, '?').join(',');
      await db.delete(_tableName,
          where: 'id IN ($placeholders)', whereArgs: list);
    } catch (e) {
      MetricsLogger.logError('EventStore.deleteByIds failed', e);
    }
  }

  Future<void> clear() async {
    await ready;
    final db = _db;
    if (db == null) return;
    try {
      await db.delete(_tableName);
    } catch (e) {
      MetricsLogger.logError('EventStore.clear failed', e);
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) return;
    try {
      await db.close();
    } catch (_) {
      // Ignore — already closed or never opened.
    }
    _db = null;
    _initCompleter = null;
  }

  Future<void> _enforceCap(Database db) async {
    final countRow =
        await db.rawQuery('SELECT COUNT(*) AS c FROM $_tableName');
    final count = (countRow.first['c'] as int?) ?? 0;
    if (count <= maxRows) return;
    final excess = count - maxRows;
    // Delete the oldest `excess` rows.
    await db.rawDelete('''
      DELETE FROM $_tableName
      WHERE id IN (
        SELECT id FROM $_tableName ORDER BY id ASC LIMIT ?
      )
    ''', [excess]);
  }
}

class StoredEvent {
  final int id;
  final Map<String, dynamic> payload;
  final int createdAtMs;

  StoredEvent({
    required this.id,
    required this.payload,
    required this.createdAtMs,
  });
}
