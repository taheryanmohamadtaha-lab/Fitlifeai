// ابزارهای فارسی: ارقام فارسی، تبدیل تاریخ به شمسی، قالب‌بندی اعداد

const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// تبدیل ارقام انگلیسی به فارسی
String faNum(Object? v) {
  final s = v.toString();
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final d = int.tryParse(ch);
    b.write(d == null ? ch : _faDigits[d]);
  }
  return b.toString();
}

/// تبدیل ارقام فارسی/عربی به انگلیسی (برای خواندن ورودی کاربر)
String enDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = fa.indexOf(ch);
    final j = ar.indexOf(ch);
    if (i >= 0) {
      b.write(i);
    } else if (j >= 0) {
      b.write(j);
    } else if (ch == '٫' || ch == '،' || ch == ',') {
      b.write('.');
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

double? parseNum(String s) {
  final t = enDigits(s).trim();
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// عدد اعشاری با تعداد رقم اعشار دلخواه، با ارقام فارسی
String fmt(num v, {int dec = 0}) {
  final s = v.toStringAsFixed(dec);
  final cleaned = dec > 0 && s.contains('.')
      ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
      : s;
  return faNum(cleaned.replaceAll('.', '٫'));
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

List<int> toJalali(int gy, int gm, int gd) {
  const gDM = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  int jy = (gy <= 1600) ? 0 : 979;
  gy -= (gy <= 1600) ? 621 : 1600;
  final gy2 = (gm > 2) ? (gy + 1) : gy;
  int days = (365 * gy) +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) -
      80 +
      gd +
      gDM[gm - 1];
  jy += 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  jy += (days - 1) ~/ 365;
  if (days > 365) days = (days - 1) % 365;
  final jm = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
  final jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
  return [jy, jm, jd];
}

const _months = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند'
];

const _weekdays = {
  1: 'دوشنبه',
  2: 'سه‌شنبه',
  3: 'چهارشنبه',
  4: 'پنجشنبه',
  5: 'جمعه',
  6: 'شنبه',
  7: 'یکشنبه',
};

String weekdayName(DateTime d) => _weekdays[d.weekday]!;

/// مثال: «سه‌شنبه ۱۹ آبان»
String jalaliLong(DateTime d) {
  final j = toJalali(d.year, d.month, d.day);
  return '${weekdayName(d)} ${faNum(j[2])} ${_months[j[1] - 1]}';
}

/// مثال: «۱۹ آبان ۱۴۰۵»
String jalaliFull(DateTime d) {
  final j = toJalali(d.year, d.month, d.day);
  return '${faNum(j[2])} ${_months[j[1] - 1]} ${faNum(j[0])}';
}

/// مثال: «۱۹ آبان»
String jalaliShort(DateTime d) {
  final j = toJalali(d.year, d.month, d.day);
  return '${faNum(j[2])} ${_months[j[1] - 1]}';
}
