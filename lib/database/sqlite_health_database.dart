import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import 'health_database.dart';

/// SQLite implementation of the HealthDatabase interface
class SQLiteHealthDatabase implements HealthDatabase {
  static const String _databaseName = 'health_tracker.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'health_records';

  Database? _database;
  final String? _customPath;

  /// Constructor with optional custom database path for testing
  SQLiteHealthDatabase({String? customPath}) : _customPath = customPath;

  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database
  Future<Database> _initDatabase() async {
    String path;
    
    if (_customPath != null) {
      path = _customPath;
    } else {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, _databaseName);
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Create the database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // Create index on timestamp for faster queries
    await db.execute('''
      CREATE INDEX idx_health_records_timestamp ON $_tableName (timestamp DESC)
    ''');

    // Create index on type for faster filtering
    await db.execute('''
      CREATE INDEX idx_health_records_type ON $_tableName (type)
    ''');
  }

  @override
  Future<void> initialize() async {
    await database; // This will trigger initialization if needed
  }

  @override
  Future<int> insertHealthRecord(HealthRecord record) async {
    final db = await database;
    
    // Use transaction to ensure data integrity
    return await db.transaction((txn) async {
      final map = record.toMap();
      map.remove('id'); // Remove ID to let SQLite auto-generate it
      
      return await txn.insert(
        _tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => HealthRecord.fromMap(map)).toList();
  }

  @override
  Future<List<HealthRecord>> getRecordsByType(HealthMetricType type) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type.toDbString()],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => HealthRecord.fromMap(map)).toList();
  }

  @override
  Future<void> deleteRecord(int id) async {
    final db = await database;
    
    // Use transaction for consistency
    await db.transaction((txn) async {
      await txn.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Get the count of records for a specific type
  Future<int> getRecordCountByType(HealthMetricType type) async {
    final db = await database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE type = ?',
      [type.toDbString()],
    );
    
    return result.first['count'] as int;
  }

  /// Get the most recent record for a specific type
  Future<HealthRecord?> getMostRecentRecordByType(HealthMetricType type) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type.toDbString()],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return HealthRecord.fromMap(maps.first);
  }

  /// Get records within a date range
  Future<List<HealthRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    HealthMetricType? type,
  }) async {
    final db = await database;
    
    String whereClause = 'timestamp >= ? AND timestamp <= ?';
    List<dynamic> whereArgs = [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.toDbString());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => HealthRecord.fromMap(map)).toList();
  }
}