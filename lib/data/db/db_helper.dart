import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app_usage.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE app_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            open_time TEXT,
            close_time TEXT,
            duration INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insertAppOpenTime(String openTime) async {
    final db = await database;
    await db.insert(
      'app_usage',
      {'open_time': openTime, 'close_time': null, 'duration': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAppCloseTime(String closeTime, int duration) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE app_usage 
      SET close_time = ?, duration = ?
      WHERE id = (SELECT MAX(id) FROM app_usage)
    ''', [closeTime, duration]);
  }

  Future<List<Map<String, dynamic>>> getAppUsageRecords() async {
    final db = await database;
    return await db.query('app_usage');
  }
}
