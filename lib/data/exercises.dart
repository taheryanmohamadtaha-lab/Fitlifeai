/// بانک تمرینات.
/// هشدار: این‌ها توضیح عمومی هستند و نسخه درمانی نیستند. فقط حرکتی که پزشک یا فیزیوتراپیست
/// برای شما تأیید کرده باید انجام شود. تعداد و مدت را خود متخصص تعیین می‌کند.

const exGroupLight = 'فعالیت‌های سبک';
const exGroupStab = 'تمرینات تثبیت‌کننده';
const exGroupFlex = 'تمرینات انعطاف‌پذیری';

const exGroups = [exGroupLight, exGroupStab, exGroupFlex];

class Exercise {
  final String id;
  final String name;
  final String group;
  final String summary;
  final List<String> steps;
  final String muscles;

  /// نمونه معمول تعداد/مدت (فقط اطلاعات عمومی؛ مقدار نهایی را متخصص تعیین می‌کند)
  final String typicalDose;
  final String difficulty;
  final List<String> contraindications;
  final List<String> warnings;

  /// تنفس: بدون حرکت درمانی، بدون نیاز به تأیید
  final bool open;

  /// زمان‌سنج جلسه به ثانیه (۰ = بدون زمان‌سنج)
  final int timerSec;

  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.summary,
    required this.steps,
    required this.muscles,
    required this.typicalDose,
    required this.difficulty,
    required this.contraindications,
    required this.warnings,
    this.open = false,
    this.timerSec = 0,
  });
}

const _commonWarnings = [
  'اگر درد کمر یا پا بیشتر شد، حرکت را همان لحظه متوقف کنید.',
  'اگر درد به پا کشیده شد، یا بی‌حسی یا گزگز تازه ایجاد شد، متوقف کنید و ثبت کنید.',
  'ضعف جدید پا، بی‌حسی ناحیه زینی یا اختلال در کنترل ادرار/مدفوع یعنی مراجعه فوری به اورژانس.',
];

const exercises = <Exercise>[
  Exercise(
    id: 'breath_diaph',
    name: 'تنفس شکمی آرام',
    group: exGroupLight,
    summary: 'تنفس آهسته با شکم برای آرام‌شدن عضلات و کاهش تنش؛ بدون حرکت ستون فقرات.',
    steps: [
      'در وضعیتی که کمرتان راحت است بنشینید یا به پشت بخوابید (زیر زانوها بالش بگذارید).',
      'یک دست را روی شکم بگذارید.',
      'آهسته از بینی نفس بکشید تا شکم کمی بالا بیاید؛ سینه کمتر حرکت کند.',
      'آهسته و بلندتر از دم، از دهان یا بینی بازدم کنید.',
      'چند نفس پشت‌سرهم ادامه دهید و شانه‌ها را شل نگه دارید.',
    ],
    muscles: 'دیافراگم، عضلات تنفسی',
    typicalDose: 'چند دقیقه، هر زمان که خواستید',
    difficulty: 'خیلی آسان',
    contraindications: ['اگر سرگیجه یا تنگی نفس پیدا کردید متوقف کنید.'],
    warnings: ['نفس را زور ندهید و حبس نکنید.'],
    open: true,
    timerSec: 180,
  ),
  Exercise(
    id: 'walk_short',
    name: 'پیاده‌روی کنترل‌شده',
    group: exGroupLight,
    summary: 'راه‌رفتن آرام روی سطح صاف با سرعتی که کمر و پا اجازه می‌دهد.',
    steps: [
      'کفش راحت و کفی‌دار بپوشید و سطح صاف و بدون پله انتخاب کنید.',
      'قامت را راحت و بدون خم‌شدن به جلو نگه دهید.',
      'با سرعتی بروید که بتوانید راحت صحبت کنید.',
      'مدت و مسافت را فقط طبق نظر متخصص زیاد کنید؛ هدف قدم روزانه اجباری وجود ندارد.',
      'اگر درد یا گزگز پا شروع شد، بایستید یا بنشینید و بعداً ادامه ندهید.',
    ],
    muscles: 'عضلات پا و لگن، قلب و عروق',
    typicalDose: 'مدت را متخصص تعیین می‌کند',
    difficulty: 'آسان',
    contraindications: [
      'درد منتشرشونده به پا که با راه‌رفتن بیشتر می‌شود',
      'ضعف پا یا زمین‌خوردن',
    ],
    warnings: _commonWarnings,
    timerSec: 0,
  ),
  Exercise(
    id: 'sit_stand_slow',
    name: 'برخاستن آرام از صندلی',
    group: exGroupLight,
    summary: 'تمرین الگوی ایمن بلندشدن و نشستن، با کمک دست‌ها و بدون خم‌شدن شدید کمر.',
    steps: [
      'روی یک صندلی محکم بنشینید، پاها به اندازه عرض شانه باز.',
      'کمی به جلو بیایید و قامت را صاف نگه دارید.',
      'با فشار پاها آرام بلند شوید؛ در صورت نیاز از دسته صندلی کمک بگیرید.',
      'آرام و کنترل‌شده بنشینید.',
    ],
    muscles: 'عضلات ران و باسن',
    typicalDose: 'تعداد را متخصص تعیین می‌کند',
    difficulty: 'آسان',
    contraindications: ['درد شدید یا ضعف پا هنگام بلندشدن'],
    warnings: _commonWarnings,
  ),
  Exercise(
    id: 'pelvic_tilt',
    name: 'چرخش آرام لگن',
    group: exGroupStab,
    summary: 'حرکت بسیار کوچک و کنترل‌شده لگن برای فعال‌کردن عضلات شکم و کمر.',
    steps: [
      'به پشت بخوابید، زانوها خم و کف پا روی زمین.',
      'شکم را کمی منقبض کنید تا کمر آرام به سمت زمین نزدیک شود.',
              'چند ثانیه نگه دارید و آرام رها کنید.',
      'دامنه حرکت را کوچک نگه دارید و نفس را حبس نکنید.',
    ],
    muscles: 'عضلات عمقی شکم، عضلات کمر',
    typicalDose: 'تعداد را متخصص تعیین می‌کند',
    difficulty: 'آسان',
    contraindications: ['افزایش درد کمر یا پا با این حرکت'],
    warnings: _commonWarnings,
  ),
  Exercise(
    id: 'glute_bridge',
    name: 'پل کوچک',
    group: exGroupStab,
    summary: 'بالا آوردن آرام لگن برای تقویت عضلات باسن، بدون قوس‌دادن زیاد کمر.',
    steps: [
      'به پشت بخوابید، زانوها خم و کف پا روی زمین.',
      'شکم را کمی منقبض کنید و با فشار پاها لگن را آرام کمی بالا ببرید.',
      'بیش از حد بالا نروید و کمر را قوس ندهید.',
      'چند ثانیه نگه دارید و آرام پایین بیایید.',
    ],
    muscles: 'عضلات باسن، پشت ران، عضلات کمر',
    typicalDose: 'تعداد را متخصص تعیین می‌کند',
    difficulty: 'متوسط',
    contraindications: ['درد کمر یا پا هنگام بالارفتن لگن'],
    warnings: _commonWarnings,
  ),
  Exercise(
    id: 'bird_dog',
    name: 'دست و پای مخالف (برد داگ)',
    group: exGroupStab,
    summary: 'ثبات ستون فقرات هنگام بلند کردن یک دست و پای مخالف، با تنه بدون چرخش.',
    steps: [
      'چهار دست و پا بایستید؛ کمر در حالت طبیعی و بدون افتادگی.',
      'شکم را کمی منقبض کنید.',
      'یک دست را به‌آرامی جلو و پای مخالف را عقب ببرید؛ لگن نچرخد.',
      'کوتاه نگه دارید و آرام برگردید، سپس سمت دیگر.',
    ],
    muscles: 'عضلات عمقی شکم و کمر، باسن، شانه',
    typicalDose: 'تعداد را متخصص تعیین می‌کند',
    difficulty: 'متوسط',
    contraindications: ['درد زانو یا مچ دست', 'افزایش درد کمر یا پا'],
    warnings: _commonWarnings,
  ),
  Exercise(
    id: 'dead_bug_arms',
    name: 'حرکت دست‌ها به پشت (دد باگ ساده)',
    group: exGroupStab,
    summary: 'کنترل شکم هنگام حرکت آرام دست‌ها، در حالی که پاها ثابت هستند.',
    steps: [
      'به پشت بخوابید، زانوها خم و کف پا روی زمین.',
      'دست‌ها را بالا و مستقیم نگه دارید.',
      'شکم را کمی منقبض کنید و یک دست را آرام به سمت بالای سر ببرید.',
      'برگردید و سمت دیگر را انجام دهید؛ کمر از زمین جدا نشود.',
    ],
    muscles: 'عضلات عمقی شکم',
    typicalDose: 'تعداد را متخصص تعیین می‌کند',
    difficulty: 'متوسط',
    contraindications: ['درد شانه', 'افزایش درد کمر یا پا'],
    warnings: _commonWarnings,
  ),
  Exercise(
    id: 'cat_camel',
    name: 'گربه و شتر با دامنه کم',
    group: exGroupFlex,
    summary: 'حرکت ملایم و کوچک ستون فقرات برای کاهش خشکی، بدون رسیدن به انتهای دامنه.',
    steps: [
      'چهار دست و پا بایستید.',
      'خیلی آرام و کم کمر را کمی گرد کنید، سپس خیلی کم به حالت برگردید.',
      'هرگز به انتهای حرکت یا نقطه دردناک نروید.',
      'نفس‌ها را آرام نگه دارید.',
    ],
    muscles: 'عضلات اطراف ستون فقرات',
    typicalDose: 'تعداد را متخصص تعیین می‌کند',
    difficulty: 'آسان',
    contraindications: ['افزایش درد کمر یا پا', 'درد زانو یا مچ دست'],
    warnings: _commonWarnings,
  ),
  Exercise(
    id: 'hamstring_towel',
    name: 'کشش ملایم پشت ران با حوله',
    group: exGroupFlex,
    summary: 'کشش آرام پشت ران؛ مراقب باشید درد یا گزگز پا شروع نشود.',
    steps: [
      'به پشت بخوابید؛ یک پا خم و کف آن روی زمین.',
      'حوله را زیر پای دیگر بگذارید و آرام بالا بیاورید تا کشش خفیفی حس کنید.',
      'اگر گزگز، سوزش یا درد پا حس شد فوراً رها کنید.',
      'کوتاه نگه دارید و آرام پایین بیاورید.',
    ],
    muscles: 'عضلات پشت ران',
    typicalDose: 'تعداد و مدت را متخصص تعیین می‌کند',
    difficulty: 'آسان',
    contraindications: [
      'درد منتشرشونده به پا یا گزگز هنگام بالا آوردن پا',
    ],
    warnings: _commonWarnings,
  ),
  Exercise(
    id: 'neck_shoulder_roll',
    name: 'شل‌کردن گردن و شانه (نشسته)',
    group: exGroupFlex,
    summary: 'حرکت ملایم شانه‌ها و گردن برای کم‌کردن تنش ناشی از نشستن طولانی.',
    steps: [
      'صاف و راحت بنشینید.',
      'شانه‌ها را آرام بالا ببرید و شل کنید.',
      'گردن را آرام به چپ و راست بچرخانید، بدون زور.',
      'نفس‌ها را آرام نگه دارید.',
    ],
    muscles: 'عضلات گردن و شانه',
    typicalDose: 'تعداد را متخصص تعیین می‌کند',
    difficulty: 'خیلی آسان',
    contraindications: ['سرگیجه یا درد گردن که به دست می‌رود'],
    warnings: _commonWarnings,
  ),
];

Exercise? exerciseById(String id) {
  for (final e in exercises) {
    if (e.id == id) return e;
  }
  return null;
}
