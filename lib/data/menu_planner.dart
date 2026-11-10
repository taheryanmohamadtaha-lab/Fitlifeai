import 'models.dart';

/// آیتم برنامه غذایی: نام ماده غذایی (دقیقاً مطابق بانک غذایی) و مقدار پایه به گرم
class PlanItem {
  final String food;
  final double grams;
  const PlanItem(this.food, this.grams);
}

/// یک آیتم برنامه که به غذای واقعی بانک وصل شده است
class ResolvedItem {
  final Food food;
  final double grams;
  ResolvedItem(this.food, this.grams);
  Nutr get n => food.per(grams);
}

class DayPlan {
  final Map<String, List<ResolvedItem>> meals;
  DayPlan(this.meals);

  Nutr get total {
    var t = Nutr.zero;
    for (final l in meals.values) {
      for (final i in l) {
        t = t + i.n;
      }
    }
    return t;
  }

  Nutr mealTotal(String meal) {
    var t = Nutr.zero;
    for (final i in meals[meal] ?? const <ResolvedItem>[]) {
      t = t + i.n;
    }
    return t;
  }
}

class MenuPlanner {
  // قالب ۷ روزه؛ مقدارها در زمان اجرا با کالری هدف کاربر مقیاس می‌شوند.
  static const _breakfast = <List<PlanItem>>[
    [PlanItem('تخم‌مرغ آب‌پز', 100), PlanItem('نان سنگک', 60), PlanItem('پنیر سفید', 30), PlanItem('خیار', 100), PlanItem('گوجه‌فرنگی', 100)],
    [PlanItem('نیمرو (با کمی روغن)', 120), PlanItem('نان بربری', 60), PlanItem('گوجه‌فرنگی', 100), PlanItem('سبزی خوردن', 30)],
    [PlanItem('املت گوجه', 250), PlanItem('نان لواش', 40), PlanItem('خیار', 100)],
    [PlanItem('جو دوسر (پرک)', 50), PlanItem('شیر کم‌چرب', 240), PlanItem('موز', 100), PlanItem('گردو', 15)],
    [PlanItem('عدسی', 250), PlanItem('نان سنگک', 40), PlanItem('سبزی خوردن', 30)],
    [PlanItem('ماست کم‌چرب', 200), PlanItem('جو دوسر (پرک)', 40), PlanItem('سیب', 150), PlanItem('گردو', 15)],
    [PlanItem('تخم‌مرغ آب‌پز', 100), PlanItem('نان تافتون', 50), PlanItem('پنیر سفید', 30), PlanItem('هویج', 80)],
  ];

  static const _lunch = <List<PlanItem>>[
    [PlanItem('برنج پخته (آبکش)', 180), PlanItem('جوجه کباب (سینه)', 130), PlanItem('سالاد شیرازی', 150), PlanItem('ماست کم‌چرب', 100)],
    [PlanItem('برنج پخته (آبکش)', 180), PlanItem('خورشت قورمه‌سبزی', 250), PlanItem('سالاد کاهو', 100), PlanItem('ماست کم‌چرب', 100)],
    [PlanItem('برنج پخته (آبکش)', 170), PlanItem('ماهی قزل‌آلا (کبابی)', 150), PlanItem('سبزی خوردن', 50), PlanItem('سالاد شیرازی', 100)],
    [PlanItem('برنج پخته (آبکش)', 150), PlanItem('خورشت قیمه', 250), PlanItem('سالاد کاهو', 100)],
    [PlanItem('برنج پخته (آبکش)', 150), PlanItem('عدس پخته', 100), PlanItem('ماست کم‌چرب', 150), PlanItem('سالاد شیرازی', 150)],
    [PlanItem('برنج پخته (آبکش)', 180), PlanItem('کباب برگ', 120), PlanItem('گوجه‌فرنگی', 100), PlanItem('سبزی خوردن', 40), PlanItem('ماست کم‌چرب', 100)],
    [PlanItem('برنج پخته (آبکش)', 150), PlanItem('خورشت کرفس', 250), PlanItem('سالاد کاهو', 100)],
  ];

  static const _dinner = <List<PlanItem>>[
    [PlanItem('آش رشته', 300), PlanItem('ماست کم‌چرب', 100)],
    [PlanItem('سینه مرغ پخته', 120), PlanItem('سیب‌زمینی آب‌پز', 150), PlanItem('سالاد کاهو', 100)],
    [PlanItem('کوکو سبزی', 150), PlanItem('نان سنگک', 40), PlanItem('ماست کم‌چرب', 100)],
    [PlanItem('سوپ جو', 300), PlanItem('تخم‌مرغ آب‌پز', 50), PlanItem('نان سنگک', 40)],
    [PlanItem('ماهی سفید (پخته)', 150), PlanItem('کدو سبز (پخته)', 150), PlanItem('نان سنگک', 30)],
    [PlanItem('میرزاقاسمی', 200), PlanItem('نان سنگک', 50), PlanItem('ماست کم‌چرب', 100)],
    [PlanItem('عدس پخته', 150), PlanItem('سالاد شیرازی', 150), PlanItem('نان سنگک', 40), PlanItem('ماست کم‌چرب', 100)],
  ];

  static const _snack = <List<PlanItem>>[
    [PlanItem('سیب', 150), PlanItem('بادام', 15)],
    [PlanItem('پرتقال', 150), PlanItem('گردو', 15)],
    [PlanItem('ماست کم‌چرب', 150), PlanItem('خیار', 100)],
    [PlanItem('کیوی', 80), PlanItem('پسته', 15)],
    [PlanItem('گلابی', 150), PlanItem('بادام', 15)],
    [PlanItem('هویج', 100), PlanItem('ماست کم‌چرب', 100)],
    [PlanItem('انگور', 100), PlanItem('گردو', 15)],
  ];

  /// dayIndex: ۰ تا ۶ (شنبه تا جمعه)
  static DayPlan build({
    required int dayIndex,
    required int targetKcal,
    required List<Food> foods,
  }) {
    final byName = {for (final f in foods) f.name: f};
    final raw = <String, List<PlanItem>>{
      'breakfast': _breakfast[dayIndex % 7],
      'lunch': _lunch[dayIndex % 7],
      'dinner': _dinner[dayIndex % 7],
      'snack': _snack[dayIndex % 7],
    };

    double base = 0;
    raw.forEach((_, items) {
      for (final i in items) {
        final f = byName[i.food];
        if (f != null) base += f.per(i.grams).kcal;
      }
    });
    var factor = base <= 0 ? 1.0 : targetKcal / base;
    if (factor < 0.7) factor = 0.7;
    if (factor > 1.6) factor = 1.6;

    final meals = <String, List<ResolvedItem>>{};
    raw.forEach((meal, items) {
      final list = <ResolvedItem>[];
      for (final i in items) {
        final f = byName[i.food];
        if (f == null) continue;
        var g = (i.grams * factor / 5).round() * 5.0;
        if (g < 5) g = 5;
        list.add(ResolvedItem(f, g));
      }
      meals[meal] = list;
    });
    return DayPlan(meals);
  }
}
