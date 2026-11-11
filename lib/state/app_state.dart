import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/calc.dart';
import '../core/fa.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../services/reminders.dart';

class AppState extends ChangeNotifier {
  bool ready = false;
  Profile? profile;
  ThemeMode themeMode = ThemeMode.dark;

  List<Food> foods = [];
  List<WeightEntry> weights = [];
  List<PainEntry> pains = [];
  List<PhotoEntry> photos = [];
  Map<String, String> settings = {};
  List<Map<String, Object?>> exLogs = [];
  int loggedDays14 = 0;

  DateTime selectedDay = dateOnly(DateTime.now());
  List<LogEntry> dayLogs = [];
  List<LogEntry> todayLogs = [];
  int todayWater = 0;

  Future<void> init() async {
    await AppDb.open();
    await _loadAll();
    ready = true;
    notifyListeners();
    if (profile != null) _rescheduleQuietly();
  }

  Future<void> _rescheduleQuietly() async {
    try {
      await ReminderService.rescheduleAll();
    } catch (_) {}
  }

  Future<void> _loadAll() async {
    final s = await AppDb.allSettings();
    settings = s;
    exLogs = await AppDb.exerciseLogs();
    profile = Profile.fromMap(s);
    themeMode = s['theme'] == 'light' ? ThemeMode.light : ThemeMode.dark;
    foods = await AppDb.foods();
    weights = await AppDb.weights();
    pains = await AppDb.pains();
    photos = await AppDb.photos();
    await _loadLogs();
  }

  /// بارگذاری دوباره همه داده‌ها (بعد از بازیابی پشتیبان)
  Future<void> reloadAll() async {
    await _loadAll();
    notifyListeners();
  }

  Future<void> _loadLogs() async {
    final today = dateKey(dateOnly(DateTime.now()));
    todayLogs = await AppDb.logsForDate(today);
    dayLogs = await AppDb.logsForDate(dateKey(selectedDay));
    todayWater = await AppDb.water(today);
    final from14 = dateKey(dateOnly(DateTime.now()).subtract(const Duration(days: 13)));
    loggedDays14 = (await AppDb.dailyTotals(from14)).length;
  }

  // ---------- مشتقات ----------
  Nutr get todayTotals => totalsOf(todayLogs);
  Nutr get dayTotals => totalsOf(dayLogs);

  Nutr totalsOf(List<LogEntry> l) {
    var t = Nutr.zero;
    for (final e in l) {
      t = t + e.n;
    }
    return t;
  }

  double get currentWeight {
    if (weights.isNotEmpty) return weights.last.kg;
    return profile?.startWeight ?? 0;
  }

  double get lostSoFar => (profile?.startWeight ?? 0) - currentWeight;

  double get bmr {
    final p = profile!;
    return Calc.bmr(male: p.male, kg: currentWeight, cm: p.heightCm, age: p.age);
  }

  double get tdee => Calc.tdee(bmr, profile!.activity);

  // ---------- پروفایل ----------
  Future<void> saveProfile(Profile p, {bool firstTime = false}) async {
    if (firstTime || p.startDate.isEmpty) {
      p.startDate = dateKey(dateOnly(DateTime.now()));
    }
    await AppDb.setSettings(p.toMap());
    profile = p;
    if (firstTime) {
      try {
        await ReminderService.requestPermission();
      } catch (_) {}
      _rescheduleQuietly();
    }
    if (firstTime && weights.isEmpty) {
      await AppDb.saveWeight(p.startDate, p.startWeight, null);
      weights = await AppDb.weights();
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode m) async {
    themeMode = m;
    await AppDb.setSettings({'theme': m == ThemeMode.light ? 'light' : 'dark'});
    notifyListeners();
  }

  // ---------- ثبت غذا ----------
  Future<void> selectDay(DateTime d) async {
    selectedDay = dateOnly(d);
    dayLogs = await AppDb.logsForDate(dateKey(selectedDay));
    notifyListeners();
  }

  Future<void> addLog({
    required String meal,
    required Food food,
    required double grams,
    DateTime? day,
  }) async {
    await AppDb.addLog(
        date: dateKey(day ?? selectedDay), meal: meal, food: food, grams: grams);
    await _loadLogs();
    notifyListeners();
  }

  Future<void> deleteLog(int id) async {
    await AppDb.deleteLog(id);
    await _loadLogs();
    notifyListeners();
  }

  // ---------- غذاها ----------
  Future<void> addCustomFood(Food f) async {
    await AppDb.insertFood(f);
    foods = await AppDb.foods();
    notifyListeners();
  }

  Future<void> deleteCustomFood(int id) async {
    await AppDb.deleteFood(id);
    foods = await AppDb.foods();
    notifyListeners();
  }

  // ---------- وزن ----------
  Future<void> saveWeight(DateTime d, double kg, double? waist) async {
    await AppDb.saveWeight(dateKey(dateOnly(d)), kg, waist);
    weights = await AppDb.weights();
    notifyListeners();
  }

  Future<void> deleteWeight(String date) async {
    await AppDb.deleteWeight(date);
    weights = await AppDb.weights();
    notifyListeners();
  }

  // ---------- تنظیمات عمومی ----------
  Future<void> setSettings(Map<String, String> m) async {
    await AppDb.setSettings(m);
    settings = await AppDb.allSettings();
    notifyListeners();
  }

  // ---------- چک‌این گرسنگی و انرژی ----------
  /// مقدار ثبت‌شده امروز: [h] گرسنگی، [e] انرژی (۱ تا ۵) یا null
  int? checkIn(String which, {DateTime? day}) {
    final raw = settings['ci_${dateKey(dateOnly(day ?? DateTime.now()))}'];
    if (raw == null || !raw.contains(',')) return null;
    final p = raw.split(',');
    return int.tryParse(which == 'h' ? p[0] : p[1]);
  }

  Future<void> saveCheckIn({int? hunger, int? energy}) async {
    final h = hunger ?? checkIn('h') ?? 0;
    final e = energy ?? checkIn('e') ?? 0;
    await setSettings({'ci_${dateKey(dateOnly(DateTime.now()))}': '$h,$e'});
  }

  /// میانگین ۷ روز اخیر (فقط مقدارهای ثبت‌شده)؛ اگر کمتر از ۳ ثبت باشد null
  double? checkInAvg(String which) {
    final vals = <int>[];
    for (var i = 0; i < 7; i++) {
      final v = checkIn(which, day: dateOnly(DateTime.now()).subtract(Duration(days: i)));
      if (v != null && v > 0) vals.add(v);
    }
    if (vals.length < 3) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  // ---------- ایمنی تمرین ----------
  /// ارزیابی متخصص ثبت شده است؟
  bool get specialistEvaluated => (settings['spine_eval_date'] ?? '').isNotEmpty;
  String get evalBy => settings['spine_eval_by'] ?? '';
  String get evalDate => settings['spine_eval_date'] ?? '';

  bool exerciseApproved(String id) => settings['ex_ok_$id'] == '1';
  String exerciseDose(String id) => settings['ex_dose_$id'] ?? '';

  /// آیا الان می‌توان این تمرین را انجام داد؟
  bool exerciseUnlocked(String id, {required bool open}) {
    if (open) return true;
    if (recentEmergency != null) return false;
    final p = profile;
    if (p != null && p.spine && !specialistEvaluated) return false;
    return exerciseApproved(id);
  }

  Future<void> logExercise(String exId, String result, int seconds) async {
    await AppDb.addExerciseLog(dateKey(dateOnly(DateTime.now())), exId, result, seconds);
    exLogs = await AppDb.exerciseLogs();
    notifyListeners();
  }

  /// آیا دو بار آخرِ این تمرین به‌خاطر درد متوقف شده؟
  bool exerciseStoppedTwice(String exId) {
    final l = exLogs.where((e) => e['ex_id'] == exId).take(2).toList();
    return l.length == 2 && l.every((e) => e['result'] == 'pain_stop');
  }

  // ---------- درد کمر و پا ----------
  Future<void> addPain(PainEntry e) async {
    await AppDb.addPain(e);
    pains = await AppDb.pains();
    notifyListeners();
  }

  Future<void> deletePain(int id) async {
    await AppDb.deletePain(id);
    pains = await AppDb.pains();
    notifyListeners();
  }

  /// آخرین ثبت درد که علائم هشدار اورژانسی دارد (در ۳ روز اخیر)
  PainEntry? get recentEmergency {
    final from = dateKey(dateOnly(DateTime.now()).subtract(const Duration(days: 3)));
    for (final e in pains.reversed) {
      if (e.date.compareTo(from) < 0) break;
      if (e.emergency) return e;
    }
    return null;
  }

  // ---------- عکس پیشرفت ----------
  Future<void> addPhoto(String path) async {
    await AppDb.addPhoto(dateKey(dateOnly(DateTime.now())), path);
    photos = await AppDb.photos();
    notifyListeners();
  }

  Future<void> deletePhoto(PhotoEntry p) async {
    await AppDb.deletePhoto(p.id);
    photos = await AppDb.photos();
    notifyListeners();
  }

  // ---------- آب ----------
  Future<void> addWater(int ml) async {
    final today = dateKey(dateOnly(DateTime.now()));
    final next = (todayWater + ml) < 0 ? 0 : todayWater + ml;
    await AppDb.setWater(today, next);
    todayWater = next;
    notifyListeners();
  }

  // ---------- حذف کامل ----------
  Future<void> wipeAll() async {
    try {
      await ReminderService.cancelAll();
    } catch (_) {}
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/progress_photos');
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (_) {}
    await AppDb.wipeUserData();
    profile = null;
    themeMode = ThemeMode.dark;
    selectedDay = dateOnly(DateTime.now());
    await _loadAll();
    notifyListeners();
  }
}
