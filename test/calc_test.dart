import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife_ai/core/calc.dart';
import 'package:fitlife_ai/core/fa.dart';
import 'package:fitlife_ai/coach/coach_engine.dart';
import 'package:fitlife_ai/data/exercises.dart';
import 'package:fitlife_ai/data/foods_seed.dart';
import 'package:fitlife_ai/data/menu_planner.dart';
import 'package:fitlife_ai/data/models.dart';
import 'package:fitlife_ai/services/reminders.dart';

void main() {
  test('BMI برای ۱۱۵ کیلو و ۱۷۵ سانتی‌متر حدود ۳۷٫۶ است', () {
    expect(Calc.bmi(115, 175), closeTo(37.55, 0.1));
    expect(Calc.bmiLabel(Calc.bmi(115, 175)), 'چاقی درجه ۲');
  });

  test('BMR با Mifflin-St Jeor', () {
    final b = Calc.bmr(male: true, kg: 115, cm: 175, age: 41);
    expect(b, closeTo(2043.75, 0.01));
  });

  test('کالری پیشنهادی و درشت‌مغذی‌ها', () {
    final b = Calc.bmr(male: true, kg: 115, cm: 175, age: 41);
    final t = Calc.tdee(b, 1.2);
    final k = Calc.suggestKcal(tdee: t, male: true);
    expect(k, 2050);
    final m = Calc.targets(kcal: k, kg: 115);
    expect(m.protein, 130);
    expect(m.fat, 72);
    expect(m.carbs, 220);
  });

  test('حداقل کالری ایمن رعایت می‌شود', () {
    expect(Calc.suggestKcal(tdee: 1600, male: true), 1500);
    expect(Calc.suggestKcal(tdee: 1400, male: false), 1200);
  });

  test('مراحل هدف از ۱۱۵ تا ۹۵', () {
    expect(Calc.milestones(115, 95), [115, 110, 105, 100, 95]);
  });

  test('تبدیل ارقام', () {
    expect(faNum(1234), '۱۲۳۴');
    expect(parseNum('۱۲٫۵'), 12.5);
  });

  test('تاریخ شمسی', () {
    expect(toJalali(2025, 3, 21), [1404, 1, 1]);
  });

  test('برنامه غذایی به کالری هدف نزدیک است', () {
    for (var d = 0; d < 7; d++) {
      final plan = MenuPlanner.build(dayIndex: d, targetKcal: 2050, foods: seedFoods);
      expect(plan.total.kcal, inInclusiveRange(1750, 2300));
    }
  });

  test('شناسه یادآوری‌ها تکراری نیست', () {
    final ids = <int>{};
    for (final d in reminderDefs) {
      for (var i = 0; i < d.repeats; i++) {
        expect(ids.add(d.baseId + i), isTrue, reason: d.key);
      }
    }
  });

  test('ثبت درد: علائم اورژانسی و رفت‌وبرگشت دیتابیس', () {
    const e = PainEntry(
      date: '2026-11-11', time: '09:00', back: 5, rleg: 3, lleg: 0,
      spread: 'باسن', numb: false, tingle: true, weak: false, saddle: true,
      bladder: false, activities: 'پیاده‌روی کوتاه،نشستن طولانی', note: '',
    );
    expect(e.emergency, isTrue);
    final r = PainEntry.fromRow({...e.toRow(), 'id': 1});
    expect(r.saddle, isTrue);
    expect(r.activityList, ['پیاده‌روی کوتاه', 'نشستن طولانی']);
    const ok = PainEntry(
      date: '2026-11-11', time: '09:00', back: 2, rleg: 0, lleg: 0,
      spread: '', numb: true, tingle: false, weak: false, saddle: false,
      bladder: false, activities: '', note: '',
    );
    expect(ok.emergency, isFalse);
  });

  test('میانگین هفتگی وزن', () {
    final w = Calc.weeklyAverages(const [
      WeightEntry('2026-11-07', 115, null), // شنبه
      WeightEntry('2026-11-09', 114, null),
      WeightEntry('2026-11-14', 113, null), // شنبه بعد
    ]);
    expect(w.length, 2);
    expect(w.first.avg, closeTo(114.5, 0.001));
    expect(w.last.avg, 113);
  });

  test('مربی: علائم اورژانسی و سؤال پزشکی رهگیری می‌شود', () {
    expect(CoachEngine.guard('بی حسی ناحیه زینی پیدا کردم')?.emergency, true);
    expect(CoachEngine.guard('کنترل ادرار ندارم')?.emergency, true);
    expect(CoachEngine.guard('امروز چی بخورم؟'), isNull);
  });

  test('بانک تمرینات: فقط تنفس باز است و شناسه‌ها یکتا', () {
    expect(exercises.where((e) => e.open).map((e) => e.id).toList(), ['breath_diaph']);
    expect(exercises.map((e) => e.id).toSet().length, exercises.length);
    expect(exerciseById('bird_dog'), isNotNull);
  });
}
