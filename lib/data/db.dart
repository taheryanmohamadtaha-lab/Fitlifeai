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
      version: 3,
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) await _createPhase2(db);
        if (oldV < 3) await _createPhase3(db);
      },
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
        await _createPhase2(db);
        await _createPhase3(db);
        final b = db.batch();
        for (final f in seedFoods) {
          b.insert('foods', f.toRow());
        }
        await b.commit(noResult: true);
      },
    );
    return _db!;
  }

  static Future<void> _createPhase2(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS pain_log(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL, time TEXT,
      back INTEGER, rleg INTEGER, lleg INTEGER, spread TEXT,
      numb INTEGER DEFAULT 0, tingle INTEGER DEFAULT 0, weak INTEGER DEFAULT 0,
      saddle INTEGER DEFAULT 0, bladder INTEGER DEFAULT 0,
      activities TEXT, note TEXT)''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pain_date ON pain_log(date)');
    await db.execute('''CREATE TABLE IF NOT EXISTS photo_log(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL, path TEXT NOT NULL)''');
  }

  static Future<void> _createPhase3(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS exercise_log(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL, ex_id TEXT NOT NULL,
      result TEXT NOT NULL, seconds INTEGER DEFAULT 0)''');
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

  // ---------- درد کمر و پا ----------
  static Future<List<PainEntry>> pains() async {
    final db = await open();
    final rows = await db.query('pain_log', orderBy: 'date, id');
    return rows.map(PainEntry.fromRow).toList();
  }

  static Future<void> addPain(PainEntry e) async {
    final db = await open();
    await db.insert('pain_log', e.toRow());
  }

  static Future<void> deletePain(int id) async {
    final db = await open();
    await db.delete('pain_log', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- عکس پیشرفت ----------
  static Future<List<PhotoEntry>> photos() async {
    final db = await open();
    final rows = await db.query('photo_log', orderBy: 'date DESC, id DESC');
    return rows
        .map((r) => PhotoEntry(r['id'] as int, r['date'] as String, r['path'] as String))
        .toList();
  }

  static Future<void> addPhoto(String date, String path) async {
    final db = await open();
    await db.insert('photo_log', {'date': date, 'path': path});
  }

  static Future<void> deletePhoto(int id) async {
    final db = await open();
    await db.delete('photo_log', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- تمرین ----------
  static Future<List<Map<String, Object?>>> exerciseLogs() async {
    final db = await open();
    return db.query('exercise_log', orderBy: 'id DESC', limit: 200);
  }

  static Future<void> addExerciseLog(String date, String exId, String result, int seconds) async {
    final db = await open();
    await db.insert('exercise_log',
        {'date': date, 'ex_id': exId, 'result': result, 'seconds': seconds});
  }

  // ---------- گزارش‌ها ----------
  /// مجموع روزانه تغذیه از تاریخ [from] به بعد
  static Future<List<Map<String, Object?>>> dailyTotals(String from) async {
    final db = await open();
    return db.rawQuery(
        'SELECT date, SUM(kcal) AS kcal, SUM(protein) AS protein, SUM(carbs) AS carbs, '
        'SUM(fat) AS fat FROM food_log WHERE date >= ? GROUP BY date ORDER BY date',
        [from]);
  }

  static Future<List<Map<String, Object?>>> waterFrom(String from) async {
    final db = await open();
    return db.query('water_log', where: 'date >= ?', whereArgs: [from], orderBy: 'date');
  }

  static Future<List<Map<String, Object?>>> allFoodLog() async {
    final db = await open();
    return db.query('food_log', orderBy: 'date, id');
  }

  // ---------- پشتیبان‌گیری ----------
  static const _backupTables = [
    'settings',
    'foods',
    'food_log',
    'weight_log',
    'water_log',
    'pain_log',
    'exercise_log',
  ];

  static Future<Map<String, Object?>> dumpAll() async {
    final db = await open();
    final out = <String, Object?>{};
    for (final t in _backupTables) {
      final rows = t == 'foods'
          ? await db.query(t, where: 'custom = 1')
          : await db.query(t);
      out[t] = rows;
    }
    return out;
  }

  static Future<void> restoreAll(Map<String, dynamic> tables) async {
    final db = await open();
    await db.transaction((txn) async {
      for (final t in _backupTables) {
        if (t == 'foods') {
          await txn.delete('foods', where: 'custom = 1');
        } else {
          await txn.delete(t);
        }
      }
      for (final t in _backupTables) {
        final rows = tables[t];
        if (rows is! List) continue;
        for (final r in rows) {
          if (r is! Map) continue;
          await txn.insert(t, Map<String, Object?>.from(r),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  // ---------- حذف کامل ----------
  static Future<void> wipeUserData() async {
    final db = await open();
    await db.delete('settings');
    await db.delete('food_log');
    await db.delete('weight_log');
    await db.delete('water_log');
    await db.delete('pain_log');
    await db.delete('exercise_log');
    await db.delete('photo_log');
    await db.delete('foods', where: 'custom = 1');
  }
}
