/// مدل‌های داده

const mealKeys = ['breakfast', 'lunch', 'dinner', 'snack'];
const mealNames = {
  'breakfast': 'صبحانه',
  'lunch': 'ناهار',
  'dinner': 'شام',
  'snack': 'میان‌وعده',
};

class Nutr {
  final double kcal, protein, carbs, fat, fiber;
  const Nutr(this.kcal, this.protein, this.carbs, this.fat, this.fiber);
  static const zero = Nutr(0, 0, 0, 0, 0);

  Nutr operator +(Nutr o) => Nutr(kcal + o.kcal, protein + o.protein,
      carbs + o.carbs, fat + o.fat, fiber + o.fiber);
}

class Profile {
  String name;
  bool male;
  int age;
  double heightCm;
  double startWeight;
  double goalWeight;
  double activity;
  int kcal, protein, carbs, fat, fiber, waterMl;
  bool spine;
  String startDate;

  Profile({
    this.name = '',
    this.male = true,
    this.age = 41,
    this.heightCm = 175,
    this.startWeight = 115,
    this.goalWeight = 95,
    this.activity = 1.2,
    this.kcal = 2050,
    this.protein = 130,
    this.carbs = 220,
    this.fat = 72,
    this.fiber = 30,
    this.waterMl = 2500,
    this.spine = true,
    this.startDate = '',
  });

  Map<String, String> toMap() => {
        'p_name': name,
        'p_male': male ? '1' : '0',
        'p_age': '$age',
        'p_height': '$heightCm',
        'p_start': '$startWeight',
        'p_goal': '$goalWeight',
        'p_activity': '$activity',
        'p_kcal': '$kcal',
        'p_protein': '$protein',
        'p_carbs': '$carbs',
        'p_fat': '$fat',
        'p_fiber': '$fiber',
        'p_water': '$waterMl',
        'p_spine': spine ? '1' : '0',
        'p_startdate': startDate,
      };

  static Profile? fromMap(Map<String, String> m) {
    if (!m.containsKey('p_age')) return null;
    return Profile(
      name: m['p_name'] ?? '',
      male: m['p_male'] != '0',
      age: int.tryParse(m['p_age'] ?? '') ?? 41,
      heightCm: double.tryParse(m['p_height'] ?? '') ?? 175,
      startWeight: double.tryParse(m['p_start'] ?? '') ?? 115,
      goalWeight: double.tryParse(m['p_goal'] ?? '') ?? 95,
      activity: double.tryParse(m['p_activity'] ?? '') ?? 1.2,
      kcal: int.tryParse(m['p_kcal'] ?? '') ?? 2050,
      protein: int.tryParse(m['p_protein'] ?? '') ?? 130,
      carbs: int.tryParse(m['p_carbs'] ?? '') ?? 220,
      fat: int.tryParse(m['p_fat'] ?? '') ?? 72,
      fiber: int.tryParse(m['p_fiber'] ?? '') ?? 30,
      waterMl: int.tryParse(m['p_water'] ?? '') ?? 2500,
      spine: m['p_spine'] != '0',
      startDate: m['p_startdate'] ?? '',
    );
  }
}

class Food {
  final int? id;
  final String name;
  final String category;
  // مقادیر برای ۱۰۰ گرم
  final double kcal, protein, carbs, fat, fiber;
  final double servingG;
  final String servingLabel;
  final bool estimated;
  final bool custom;

  const Food({
    this.id,
    required this.name,
    required this.category,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.servingG,
    required this.servingLabel,
    this.estimated = false,
    this.custom = false,
  });

  Nutr per(double grams) {
    final k = grams / 100.0;
    return Nutr(kcal * k, protein * k, carbs * k, fat * k, fiber * k);
  }

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'serving_g': servingG,
        'serving_label': servingLabel,
        'estimated': estimated ? 1 : 0,
        'custom': custom ? 1 : 0,
      };

  factory Food.fromRow(Map<String, Object?> r) => Food(
        id: r['id'] as int?,
        name: r['name'] as String,
        category: r['category'] as String,
        kcal: (r['kcal'] as num).toDouble(),
        protein: (r['protein'] as num).toDouble(),
        carbs: (r['carbs'] as num).toDouble(),
        fat: (r['fat'] as num).toDouble(),
        fiber: (r['fiber'] as num).toDouble(),
        servingG: (r['serving_g'] as num).toDouble(),
        servingLabel: r['serving_label'] as String,
        estimated: (r['estimated'] as int) == 1,
        custom: (r['custom'] as int) == 1,
      );
}

class LogEntry {
  final int id;
  final String date;
  final String meal;
  final int? foodId;
  final String name;
  final double grams;
  final Nutr n;

  const LogEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.foodId,
    required this.name,
    required this.grams,
    required this.n,
  });

  factory LogEntry.fromRow(Map<String, Object?> r) => LogEntry(
        id: r['id'] as int,
        date: r['date'] as String,
        meal: r['meal'] as String,
        foodId: r['food_id'] as int?,
        name: r['name'] as String,
        grams: (r['grams'] as num).toDouble(),
        n: Nutr(
          (r['kcal'] as num).toDouble(),
          (r['protein'] as num).toDouble(),
          (r['carbs'] as num).toDouble(),
          (r['fat'] as num).toDouble(),
          (r['fiber'] as num).toDouble(),
        ),
      );
}

class WeightEntry {
  final String date;
  final double kg;
  final double? waist;
  const WeightEntry(this.date, this.kg, this.waist);
}
