import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_limit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('intention.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS app_limits');
        await db.execute('DROP TABLE IF EXISTS override_log');
        await db.execute('DROP TABLE IF EXISTS usage_records');
        await _createDB(db, newVersion);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
  await db.execute('''
    CREATE TABLE app_limits (
      packageName TEXT PRIMARY KEY,
      displayName TEXT NOT NULL,
      dailyLimitMinutes INTEGER NOT NULL,
      isEnabled INTEGER NOT NULL DEFAULT 1,
      usedMinutesToday INTEGER NOT NULL DEFAULT 0,
      overrideCount INTEGER NOT NULL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE override_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      packageName TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      tierReached INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE usage_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      packageName TEXT NOT NULL,
      date TEXT NOT NULL,
      totalMinutes INTEGER NOT NULL DEFAULT 0
    )
  ''');
}

  // App Limits CRUD
  Future<void> insertAppLimit(AppLimit limit) async {
    final db = await database;
    await db.insert(
      'app_limits',
      limit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AppLimit>> getAllAppLimits() async {
    final db = await database;
    final maps = await db.query('app_limits');
    return maps.map((m) => AppLimit.fromMap(m)).toList();
  }

  Future<void> updateAppLimit(AppLimit limit) async {
    final db = await database;
    await db.update(
      'app_limits',
      limit.toMap(),
      where: 'packageName = ?',
      whereArgs: [limit.packageName],
    );
  }

  Future<void> deleteAppLimit(String packageName) async {
    final db = await database;
    await db.delete(
      'app_limits',
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  // Override log
  Future<void> logOverride(String packageName, int tierReached) async {
    final db = await database;
    await db.insert('override_log', {
      'packageName': packageName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'tierReached': tierReached,
    });
  }

  // Reset daily usage (call at midnight)
  Future<void> resetDailyUsage() async {
    final db = await database;
    await db.update('app_limits', {
      'usedMinutesToday': 0,
      'overrideCount': 0,
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}