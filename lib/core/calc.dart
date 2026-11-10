import '../data/models.dart';
import 'fa.dart';

/// موتور محاسبات تغذیه و کاهش وزن (Mifflin-St Jeor)
class Calc {
  static double bmi(double kg, double cm) {
    final m = cm / 100;
    return kg / (m * m);
  }

  static String bmiLabel(double b) {
    if (b < 18.5) return 'کم‌وزن';
    if (b < 25) return 'وزن طبیعی';
    if (b < 30) return 'اضافه‌وزن';
    if (b < 35) return 'چاقی درجه ۱';
    if (b < 40) return 'چاقی درجه ۲';
    return 'چاقی درجه ۳';
  }

  static double bmr({
    required bool male,
    required double kg,
    required double cm,
    required int age,
  }) {
    return 10 * kg + 6.25 * cm - 5 * age + (male ? 5 : -161);
  }

  static double tdee(double bmr, double activity) => bmr * activity;

  static int minSafeKcal(bool male) => male ? 1500 : 1200;

  /// کالری پیشنهادی با کسری ملایم (پیش‌فرض ۴۰۰ کیلوکالری)
  static int suggestKcal({
    required double tdee,
    required bool male,
    double deficit = 400,
  }) {
    var k = ((tdee - deficit) / 50).round() * 50;
    final min = minSafeKcal(male);
    if (k < min) k = min;
    return k;
  }

  /// درشت‌مغذی‌ها: پروتئین ۱٫۱۳ گرم به ازای هر کیلو، چربی ≈ ۳۱٫۵٪ کالری، بقیه کربوهیدرات
  static Targets targets({required int kcal, required double kg}) {
    final protein = (kg * 1.13).round();
    final fat = (kcal * 0.315 / 9).round();
    var carbs = ((kcal - protein * 4 - fat * 9) / 4).floor();
    if (carbs < 0) carbs = 0;
    final fiber = kcal >= 1800 ? 30 : 25;
    return Targets(kcal, protein, carbs, fat, fiber);
  }

  /// کاهش وزن هفتگی تخمینی (کیلوگرم) بر اساس کسری کالری
  static double weeklyLossKg({required double tdee, required int kcal}) {
    final deficit = tdee - kcal;
    if (deficit <= 0) return 0;
    return deficit * 7 / 7700;
  }

  /// تخمین تعداد هفته تا رسیدن به هدف
  static int? weeksToGoal({required double remainingKg, required double weeklyKg}) {
    if (remainingKg <= 0) return 0;
    if (weeklyKg <= 0.01) return null;
    return (remainingKg / weeklyKg).ceil();
  }

  /// مراحل هدف: هر ۵ کیلوگرم یک مرحله
  static List<double> milestones(double start, double goal) {
    final list = <double>[start];
    var w = start - 5;
    while (w > goal + 0.01) {
      list.add(w);
      w -= 5;
    }
    list.add(goal);
    return list;
  }

  /// میانگین هفتگی وزن (هفته از شنبه شروع می‌شود)
  static List<WeekAvg> weeklyAverages(List<WeightEntry> entries) {
    final map = <String, List<double>>{};
    final starts = <String, DateTime>{};
    for (final e in entries) {
      final d = parseKey(e.date);
      final offset = (d.weekday + 1) % 7;
      final s = DateTime(d.year, d.month, d.day - offset);
      final k = dateKey(s);
      map.putIfAbsent(k, () => []).add(e.kg);
      starts[k] = s;
    }
    final keys = map.keys.toList()..sort();
    return [
      for (final k in keys)
        WeekAvg(starts[k]!, map[k]!.reduce((a, b) => a + b) / map[k]!.length, map[k]!.length)
    ];
  }
}

class Targets {
  final int kcal, protein, carbs, fat, fiber;
  const Targets(this.kcal, this.protein, this.carbs, this.fat, this.fiber);
}

class WeekAvg {
  final DateTime start;
  final double avg;
  final int count;
  WeekAvg(this.start, this.avg, this.count);
}
