import 'package:flutter/material.dart';

import '../core/calc.dart';
import '../core/fa.dart';
import '../data/db.dart';
import '../data/models.dart';

class AppState extends ChangeNotifier {
  bool ready = false;
  Profile? profile;
  ThemeMode themeMode = ThemeMode.dark;

  List<Food> foods = [];
  List<WeightEntry> weights = [];

  DateTime selectedDay = dateOnly(DateTime.now());
  List<LogEntry> dayLogs = [];
  List<LogEntry> todayLogs = [];
  int todayWater = 0;

  Future<void> init() async {
    await AppDb.open();
    await _loadAll();
    ready = true;
    notifyListeners();
  }

  Future<void> _loadAll() async {
    final s = await AppDb.allSettings();
    profile = Profile.fromMap(s);
    themeMode = s['theme'] == 'light' ? ThemeMode.light : ThemeMode.dark;
    foods = await AppDb.foods();
    weights = await AppDb.weights();
    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    final today = dateKey(dateOnly(DateTime.now()));
    todayLogs = await AppDb.logsForDate(today);
    dayLogs = await AppDb.logsForDate(dateKey(selectedDay));
    todayWater = await AppDb.water(today);
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
    await AppDb.wipeUserData();
    profile = null;
    themeMode = ThemeMode.dark;
    selectedDay = dateOnly(DateTime.now());
    await _loadAll();
    notifyListeners();
  }
}
