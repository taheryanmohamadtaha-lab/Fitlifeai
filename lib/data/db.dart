import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'foods_seed.dart';
import 'models.dart';

/// پایگاه داده محلی (SQLite) — همه اطلاعات فقط روی گوشی ذخیره می‌شود.
class AppDb {
  static Database? _db;

  static Future<Database> open() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'fitlife.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE settings(k TEXT PRIMARY KEY, v TEXT)');
        await db.execute('''CREATE TABLE foods(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL, category TEXT NOT NULL,
          kcal REAL, protein REAL, carbs REAL, fat REAL, fiber REAL,
          serving_g REAL, serving_label TEXT,
          estimated INTEGER DEFAULT 0, custom INTEGER DEFAULT 0)''');
        await db.execute('''CREATE TABLE food_log(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL, meal TEXT NOT NULL, food_id INTEGER,
          name TEXT NOT NULL, grams REAL,
          kcal REAL, protein REAL, carbs REAL, fat REAL, fiber REAL)''');
        await db.execute('CREATE INDEX idx_log_date ON food_log(date)');
        await db.execute(
            'CREATE TABLE weight_log(date TEXT PRIMARY KEY, kg REAL NOT NULL, waist REAL)');
        await db.execute(
            'CREATE TABLE water_log(date TEXT PRIMARY KEY, ml INTEGER NOT NULL)');
        final b = db.batch();
        for (final f in seedFoods) {
          b.insert('foods', f.toRow());
        }
        await b.commit(noResult: true);
      },
    );
    return _db!;
  }

  // ---------- تنظیمات / پروفایل ----------
  static Future<Map<String, String>> allSettings() async {
    final db = await open();
    final rows = await db.query('settings');
    return {for (final r in rows) r['k'] as String: r['v'] as String};
  }

  static Future<void> setSettings(Map<String, String> m) async {
    final db = await open();
    final b = db.batch();
    m.forEach((k, v) {
      b.insert('settings', {'k': k, 'v': v},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await b.commit(noResult: true);
  }

  // ---------- غذاها ----------
  static Future<List<Food>> foods() async {
    final db = await open();
    final rows = await db.query('foods', orderBy: 'category, name');
    return rows.map(Food.fromRow).toList();
  }

  static Future<int> insertFood(Food f) async {
    final db = await open();
    return db.insert('foods', f.toRow());
  }

  static Future<void> deleteFood(int id) async {
    final db = await open();
    await db.delete('foods', where: 'id = ? AND custom = 1', whereArgs: [id]);
  }

  // ---------- ثبت غذا ----------
  static Future<List<LogEntry>> logsForDate(String date) async {
    final db = await open();
    final rows = await db.query('food_log',
        where: 'date = ?', whereArgs: [date], orderBy: 'id');
    return rows.map(LogEntry.fromRow).toList();
  }

  static Future<void> addLog({
    required String date,
    required String meal,
    required Food food,
    required double grams,
  }) async {
    final db = await open();
    final n = food.per(grams);
    await db.insert('food_log', {
      'date': date,
      'meal': meal,
      'food_id': food.id,
      'name': food.name,
      'grams': grams,
      'kcal': n.kcal,
      'protein': n.protein,
      'carbs': n.carbs,
      'fat': n.fat,
      'fiber': n.fiber,
    });
  }

  static Future<void> deleteLog(int id) async {
    final db = await open();
    await db.delete('food_log', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- وزن ----------
  static Future<List<WeightEntry>> weights() async {
    final db = await open();
    final rows = await db.query('weight_log', orderBy: 'date');
    return rows
        .map((r) => WeightEntry(r['date'] as String,
            (r['kg'] as num).toDouble(), (r['waist'] as num?)?.toDouble()))
        .toList();
  }

  static Future<void> saveWeight(String date, double kg, double? waist) async {
    final db = await open();
    await db.insert('weight_log', {'date': date, 'kg': kg, 'waist': waist},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteWeight(String date) async {
    final db = await open();
    await db.delete('weight_log', where: 'date = ?', whereArgs: [date]);
  }

  // ---------- آب ----------
  static Future<int> water(String date) async {
    final db = await open();
    final r = await db.query('water_log', where: 'date = ?', whereArgs: [date]);
    if (r.isEmpty) return 0;
    return r.first['ml'] as int;
  }

  static Future<void> setWater(String date, int ml) async {
    final db = await open();
    await db.insert('water_log', {'date': date, 'ml': ml < 0 ? 0 : ml},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------- حذف کامل ----------
  static Future<void> wipeUserData() async {
    final db = await open();
    await db.delete('settings');
    await db.delete('food_log');
    await db.delete('weight_log');
    await db.delete('water_log');
    await db.delete('foods', where: 'custom = 1');
  }
}
