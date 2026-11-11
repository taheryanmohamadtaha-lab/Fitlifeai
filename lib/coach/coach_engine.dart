import '../core/calc.dart';
import '../core/fa.dart';
import '../data/foods_seed.dart';
import '../data/models.dart';
import '../state/app_state.dart';

class CoachReply {
  final String text;
  final bool emergency;
  const CoachReply(this.text, {this.emergency = false});
}

/// موتور آفلاین «مربی هوشمند من»: قانون‌محور، بدون اینترنت، بدون تشخیص یا تجویز.
class CoachEngine {
  /// یکسان‌سازی متن فارسی برای جست‌وجو
  static String norm(String s) {
    var t = enDigits(s)
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('‌', ' ')
        .replaceAll('ً', '')
        .replaceAll('ٌ', '')
        .replaceAll('ٍ', '')
        .replaceAll('َ', '')
        .replaceAll('ُ', '')
        .replaceAll('ِ', '')
        .replaceAll('ّ', '')
        .toLowerCase();
    t = t.replaceAll(RegExp(r'[^؀-ۿa-z0-9 ]'), ' ');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _has(String q, List<String> words) {
    for (final w in words) {
      if (q.contains(norm(w))) return true;
    }
    return false;
  }

  static const emergencyMessage =
      'این علائم می‌تواند اورژانسی باشد. لطفاً همین حالا به اورژانس یا نزدیک‌ترین مرکز درمانی مراجعه کنید '
      'و منتظر بهتر شدن نمانید. من نمی‌توانم این وضعیت را ارزیابی کنم.';

  /// پیش‌بررسی ایمنی؛ اگر پاسخ ثابت لازم باشد، همان را برمی‌گرداند (پیام هرگز به سرویس آنلاین نمی‌رود)
  static CoachReply? guard(String raw) {
    final q = norm(raw);
    final saddle = _has(q, ['زینی', 'مقعد', 'بی حسی زینی', 'بی حسی ناحیه زینی', 'بی حسی اطراف مقعد', 'بی حسی بین پا', 'بی حسی ناحیه تناسلی']);
    final bladder = _has(q, [
      'کنترل ادرار',
      'ادرار ندارم',
      'نمی تونم مدفوع',
      'نمی تونم ادرار',
      'نمیتونم ادرار',
      'بی اختیاری ادرار',
      'کنترل مدفوع',
      'بی اختیاری مدفوع',
      'احتباس ادرار'
    ]);
    final weak = _has(q, [
      'ضعف پا',
      'پام ضعیف',
      'پام بی حس',
      'پام قفل',
      'پام حس ندار',
      'پام کشیده نمی شه',
      'زمین می خورم',
      'پام شل'
    ]);
    if (saddle || bladder || weak) return const CoachReply(emergencyMessage, emergency: true);

    if (_has(q, [
      'دارو',
      'قرص',
      'آمپول',
      'تزریق',
      'مسکن',
      'بروفن',
      'ژلوفن',
      'دیکلوفناک',
      'مصرف کنم',
      'عمل جراحی',
      'عمل کنم',
      'تشخیص',
      'بیماری من چیه',
      'آیا دیسک',
      'پارگی دیسک',
      'فتق',
      'ام آر آی',
      'mri',
      'سیاتیک دارم',
    ])) {
      return const CoachReply(
          'من تشخیص بیماری نمی‌دهم و دارو یا درمان تجویز نمی‌کنم؛ این کار فقط با پزشک یا فیزیوتراپیست شما ممکن است. '
          'می‌توانم در تغذیه، کالری، پیگیری وزن و استفاده از برنامه کمکتان کنم. اگر درد یا علائم تازه‌ای دارید، آن را در بخش پایش درد ثبت کنید و خلاصه‌اش را به پزشک نشان دهید.');
    }
    return null;
  }

  static CoachReply answer(String raw, AppState s) {
    final g = guard(raw);
    if (g != null) return g;
    final q = norm(raw);
    final p = s.profile!;
    final t = s.todayTotals;

    // ---------- ورزش ----------
    if (_has(q, ['ورزش', 'تمرین', 'حرکت', 'کرانچ', 'دراز نشست', 'شنا', 'دویدن', 'دو ', 'باشگاه', 'وزنه', 'یوگا', 'کشش', 'پیاده روی'])) {
      return const CoachReply(
          'برای شما (با مشکل دیسک و درد منتشرشونده به پا) هر ورزش یا حرکت اصلاحی باید فقط بعد از ارزیابی و تأیید پزشک یا فیزیوتراپیست باشد. '
          'من هیچ تمرین درمانی پیشنهاد نمی‌کنم و حرکاتی مثل کرانچ، دراز و نشست، پرش یا چرخش تحت فشار را هم پیش‌فرض توصیه نمی‌کنم.\n\n'
          'اگر متخصص حرکتی را تأیید کرد، در «تمرینات تأییدشده» ثبتش کنید. تا آن موقع، تنفس آرام همیشه در دسترس است. '
          'کاهش وزن را فعلاً با تغذیه پیش ببرید.');
    }

    // ---------- کاهش سریع ----------
    if (_has(q, ['سریع', 'هفته ای ۳', 'هفته ای 3', 'رژیم سخت', 'گرسنگی بدم', 'گرسنگی بکشم', 'لاغر شم تا', 'شبانه', 'نخورم', 'حذف کامل', 'روزه بگیرم', 'کالری کمتر', 'کمتر بخورم'])) {
      return CoachReply(
          'کاهش وزن سریع یا خوردن خیلی کم هم برای کمر و هم برای عضلات و انرژی شما خوب نیست و معمولاً دوام ندارد. '
          'سرعت مناسب حدود ۰٫۲۵ تا ۰٫۷۵ کیلوگرم در هفته است. کالری فعلی شما ${fmt(p.kcal)} است و پایین‌تر از ${fmt(Calc.minSafeKcal(p.male))} کیلوکالری توصیه نمی‌شود. '
          'اگر می‌خواهید سریع‌تر پیش بروید، قبل از هر تغییر با پزشک یا متخصص تغذیه مشورت کنید.');
    }

    // ---------- تحلیل روند ----------
    if (_has(q, ['روند', 'تحلیل', 'پیشرفت', 'چقدر مونده', 'چقدر مانده', 'چند هفته', 'کی میرسم', 'کی می رسم', 'وزنم', 'کاهش وزن'])) {
      return CoachReply(trendAnalysis(s));
    }

    // ---------- کالری امروز ----------
    if (_has(q, ['کالری امروز', 'چقدر خوردم', 'کالری باقی', 'کالری مونده', 'کالری مانده', 'چقدر کالری', 'بررسی امروز', 'امروز چطور'])) {
      return CoachReply(todaySummary(s));
    }

    // ---------- آب ----------
    if (_has(q, ['آب', 'نوشیدن', 'تشنه'])) {
      final left = p.waterMl - s.todayWater;
      return CoachReply(left > 0
          ? 'تا الان ${fmt(s.todayWater)} از ${fmt(p.waterMl)} میلی‌لیتر آب نوشیده‌اید؛ ${fmt(left)} میلی‌لیتر مانده. بین روز در چند نوبت یک لیوان بنوشید. اگر پزشک محدودیت مایعات گفته، همان را رعایت کنید.'
          : 'آفرین! به هدف آب امروز (${fmt(p.waterMl)} میلی‌لیتر) رسیده‌اید.');
    }

    // ---------- پروتئین ----------
    if (_has(q, ['پروتئین', 'ماهیچه', 'عضله'])) {
      final left = p.protein - t.protein;
      final tips = _suggest(s, protein: true).join('، ');
      return CoachReply(left > 0
          ? 'پروتئین امروز: ${fmt(t.protein)} از ${fmt(p.protein)} گرم (${fmt(left)} گرم مانده). گزینه‌های مناسب: $tips.'
          : 'پروتئین امروز به هدف رسیده (${fmt(t.protein)} از ${fmt(p.protein)} گرم). همین روند خوب است.');
    }

    // ---------- گرسنگی ----------
    if (_has(q, ['گرسنه', 'گرسنگی', 'هوس', 'شیرینی', 'اشتها', 'سیر نمی'])) {
      return const CoachReply(
          'چند کار کوچک کمک می‌کند: یک لیوان آب بنوشید، به غذاهای پروتئین‌دار و پرفیبر (حبوبات، سبزی، ماست، تخم‌مرغ) بیشتر تکیه کنید، آهسته بخورید و میان‌وعده‌ی برنامه‌ریزی‌شده داشته باشید. '
          'برای هوس شیرینی، یک میوه یا ماست کم‌چرب با کمی خرما انتخاب خوبی است. اگر گرسنگی شدید و دائمی است، احساس ضعف دارید یا سرگیجه می‌کنید، به پزشک بگویید.');
    }

    // ---------- پیشنهاد غذا ----------
    if (_has(q, ['چی بخورم', 'چه بخورم', 'پیشنهاد', 'شام چی', 'ناهار چی', 'صبحانه چی', 'میان وعده', 'میانوعده', 'غذای سالم'])) {
      final left = p.kcal - t.kcal;
      final tips = _suggest(s, protein: p.protein - t.protein > 25).join('، ');
      return CoachReply(left > 150
          ? 'تا هدف امروز حدود ${fmt(left)} کیلوکالری مانده. پیشنهادها: $tips. مقدار را از «بانک غذا» ببینید و بعد از خوردن ثبت کنید.'
          : 'کالری امروز تقریباً تمام شده. اگر گرسنه‌اید، سبزی و سالاد، خیار یا ماست کم‌چرب انتخاب‌های سبکی هستند.');
    }

    // ---------- ارزش غذایی یک غذا ----------
    final food = _findFood(q, s.foods);
    if (food != null) return CoachReply(_foodInfo(food));

    // ---------- انگیزه ----------
    if (_has(q, ['انگیزه', 'خسته', 'ناامید', 'نمیشه', 'نمی شه', 'سخته', 'بی حوصله', 'ول کنم', 'شکست'])) {
      return CoachReply(
          'درکتان می‌کنم؛ مسیر کاهش وزن بالا و پایین دارد. چیزی که مهم است ادامه‌دادن عادت‌های سالم است، نه یک روز کامل. '
          'تا الان ${fmt(s.lostSoFar, dec: 1)} کیلوگرم از شروع کم کرده‌اید و ${fmt(s.currentWeight - p.goalWeight, dec: 1)} کیلوگرم تا هدف مانده. '
          'امروز فقط یک کار کوچک انتخاب کنید: ثبت یک وعده یا یک لیوان آب.');
    }

    // ---------- راهنمای برنامه ----------
    if (_has(q, ['چطور', 'چگونه', 'کجا', 'چه جوری', 'راهنما', 'ثبت', 'پشتیبان', 'یادآور', 'یاداوری', 'عکس', 'گزارش', 'تنظیمات', 'حذف'])) {
      return const CoachReply(
          'راهنمای سریع:\n'
          '• ثبت غذا: تب «تغذیه» ← افزودن غذا\n'
          '• ثبت وزن و دور شکم: تب «پیشرفت»\n'
          '• آب: روی کارت آب در داشبورد + و − بزنید\n'
          '• درد کمر و پا، گزارش‌ها، یادآوری‌ها، عکس‌ها و پشتیبان‌گیری: تب «من»\n'
          '• تغییر هدف‌ها: تب «من» ← ویرایش اطلاعات و هدف‌ها\n'
          '• غذای جدید: تب «بانک غذا» ← غذای جدید');
    }

    // ---------- سلام ----------
    if (_has(q, ['سلام', 'درود', 'وقت بخیر', 'صبح بخیر', 'عصر بخیر', 'شب بخیر'])) {
      return CoachReply('سلام${p.name.isEmpty ? '' : ' ${p.name}'}! من مربی هوشمند شما هستم. ${todaySummary(s)}');
    }

    return const CoachReply(
        'می‌توانم درباره این موضوع‌ها کمک کنم: کالری و درشت‌مغذی‌های امروز، ارزش غذایی غذاها (مثلاً «برنج چقدر کالری دارد؟»)، '
        'پیشنهاد غذا، تحلیل روند وزن، آب، گرسنگی، انگیزه و راهنمای برنامه. '
        'تشخیص بیماری، دارو و تمرین درمانی از من برنمی‌آید و باید با متخصص باشد.');
  }

  static String todaySummary(AppState s) {
    final p = s.profile!;
    final t = s.todayTotals;
    final left = p.kcal - t.kcal;
    if (s.todayLogs.isEmpty) {
      return 'امروز هنوز غذایی ثبت نشده. هدف کالری شما ${fmt(p.kcal)} کیلوکالری است.';
    }
    final b = StringBuffer(
        'امروز ${fmt(t.kcal)} از ${fmt(p.kcal)} کیلوکالری مصرف کرده‌اید'
        '${left >= 0 ? ' (${fmt(left)} مانده)' : ' (${fmt(-left)} بیشتر از هدف)'}. '
        'پروتئین ${fmt(t.protein)}/${fmt(p.protein)} گرم، کربوهیدرات ${fmt(t.carbs)}/${fmt(p.carbs)} گرم، چربی ${fmt(t.fat)}/${fmt(p.fat)} گرم.');
    if (left < -p.kcal * 0.1) {
      b.write(' کمی بالاتر از هدف است؛ نگران نشوید، وعده بعدی را سبک‌تر انتخاب کنید.');
    }
    return b.toString();
  }

  /// تحلیل روند وزن + پیشنهاد اصلاح تدریجی (فقط پیشنهاد، نه دستور)
  static String trendAnalysis(AppState s) {
    final p = s.profile!;
    final cur = s.currentWeight;
    final toGoal = cur - p.goalWeight;
    final b = StringBuffer(
        'وزن فعلی ${fmt(cur, dec: 1)} کیلوگرم است، ${fmt(s.lostSoFar, dec: 1)} کیلوگرم از شروع کم شده و ${fmt(toGoal < 0 ? 0 : toGoal, dec: 1)} کیلوگرم تا هدف مانده. ');

    final weeks = Calc.weeklyAverages(s.weights);
    if (weeks.length < 2) {
      b.write('برای تحلیل دقیق روند، دست‌کم دو هفته وزن‌گیری منظم (چند بار در هفته) لازم است.');
      return b.toString();
    }
    final used = weeks.length > 4 ? weeks.sublist(weeks.length - 4) : weeks;
    final rate = (used.first.avg - used.last.avg) / (used.length - 1); // کیلوگرم کاهش در هفته

    final loggedDays = s.loggedDays14;
    final hunger = s.checkInAvg('h');
    final energy = s.checkInAvg('e');

    b.write('میانگین کاهش در هفته‌های اخیر حدود ${fmt(rate, dec: 2)} کیلوگرم در هفته است. ');
    if (rate > 0.75) {
      b.write('این سرعت کمی زیاد است. اگر انرژی یا گرسنگی‌تان مشکل دارد، ۱۰۰ تا ۲۰۰ کیلوکالری به برنامه اضافه کنید (مثلاً یک میان‌وعده پروتئین‌دار) و با پزشک مشورت کنید.');
    } else if (rate >= 0.2) {
      b.write('این سرعت در محدوده خوب است؛ همین روند را ادامه دهید.');
    } else if (rate >= 0) {
      if (loggedDays >= 9) {
        b.write('کاهش کند یا ثابت شده. اول دقت اندازه وعده‌ها و ثبت نوشیدنی‌ها و تنقلات را بررسی کنید. اگر دو هفته دیگر هم ثابت ماند، می‌توانید کالری را حداکثر ۱۰۰ تا ۱۵۰ کیلوکالری کم کنید (نه کمتر از ${fmt(Calc.minSafeKcal(p.male))}).');
      } else {
        b.write('ثبت غذا در دو هفته اخیر کم بوده (${fmt(loggedDays)} روز از ۱۴ روز)، پس نمی‌توان با اطمینان گفت چرا روند کند است. چند روز منظم ثبت کنید.');
      }
    } else {
      b.write('وزن در حال افزایش است. نوسان آب و نمک و وعده‌های اخیر می‌تواند باعث این تغییر باشد؛ ثبت منظم‌تر و بررسی میانگین هفتگی کمک می‌کند. اگر چند هفته ادامه یافت، با متخصص تغذیه صحبت کنید.');
    }
    if (hunger != null && hunger >= 4) {
      b.write(' گرسنگی‌تان در روزهای اخیر زیاد ثبت شده؛ فعلاً کالری را کمتر نکنید و پروتئین و فیبر را بیشتر کنید.');
    }
    if (energy != null && energy <= 2) {
      b.write(' انرژی‌تان پایین ثبت شده؛ اگر ضعف یا خستگی ادامه دارد، حتماً به پزشک بگویید.');
    }
    return b.toString();
  }

  static List<String> _suggest(AppState s, {required bool protein}) {
    final all = s.foods;
    final day = DateTime.now().day;
    Iterable<Food> pool;
    if (protein) {
      pool = all.where((f) => (f.category == catMeat || f.category == catDairy || f.category == catLegume) && f.kcal > 0);
      final l = pool.toList()
        ..sort((a, b) => (b.protein / (b.kcal + 1)).compareTo(a.protein / (a.kcal + 1)));
      final top = l.take(8).toList();
      return [for (var i = 0; i < 3 && top.isNotEmpty; i++) top[(day + i) % top.length].name];
    }
    pool = all.where((f) => f.category == catVeg || f.category == catFruit || f.category == catDairy);
    final l = pool.toList()..sort((a, b) => a.kcal.compareTo(b.kcal));
    final top = l.take(12).toList();
    return [for (var i = 0; i < 3 && top.isNotEmpty; i++) top[(day + i * 2) % top.length].name];
  }

  static Food? _findFood(String q, List<Food> foods) {
    Food? best;
    var bestLen = 0;
    for (final f in foods) {
      final name = norm(f.name.replaceAll(RegExp(r'\([^)]*\)'), ''));
      if (name.isEmpty) continue;
      if (q.contains(name) && name.length > bestLen) {
        best = f;
        bestLen = name.length;
      }
    }
    if (best != null) return best;
    // تطبیق بر اساس واژه اول نام (مثل «برنج»)
    for (final f in foods) {
      final first = norm(f.name.replaceAll(RegExp(r'\([^)]*\)'), '')).split(' ').first;
      if (first.length >= 3 && q.split(' ').contains(first)) return f;
    }
    return null;
  }

  static String _foodInfo(Food f) {
    final n = f.per(f.servingG);
    final h = f.per(100);
    return '«${f.name}»: هر ${f.servingLabel} (حدود ${fmt(f.servingG)} گرم) تقریباً ${fmt(n.kcal)} کیلوکالری، '
        'پروتئین ${fmt(n.protein, dec: 1)} گرم، کربوهیدرات ${fmt(n.carbs, dec: 1)} گرم و چربی ${fmt(n.fat, dec: 1)} گرم دارد. '
        'در ۱۰۰ گرم: ${fmt(h.kcal)} کیلوکالری.${f.estimated ? ' (این مقدار تخمینی است؛ به روش پخت بستگی دارد.)' : ''}';
  }
}
