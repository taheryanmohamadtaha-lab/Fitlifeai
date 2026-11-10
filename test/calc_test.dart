import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife_ai/core/calc.dart';
import 'package:fitlife_ai/core/fa.dart';
import 'package:fitlife_ai/data/foods_seed.dart';
import 'package:fitlife_ai/data/menu_planner.dart';

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
}
