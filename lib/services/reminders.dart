import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/db.dart';

/// تعریف یک یادآوری
class ReminderDef {
  final String key;
  final String title;
  final String body;
  final IconData icon;
  final int defaultHour;
  final int defaultMinute;
  final bool defaultOn;
  final int baseId;

  /// چند بار در روز تکرار شود (با فاصله [everyMinutes] از زمان انتخاب‌شده)
  final int repeats;
  final int everyMinutes;

  /// برای یادآوری هفتگی: روز هفته (DateTime.friday ...)
  final int? weekday;

  const ReminderDef({
    required this.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.defaultHour,
    required this.defaultMinute,
    required this.baseId,
    this.defaultOn = false,
    this.repeats = 1,
    this.everyMinutes = 0,
    this.weekday,
  });

  String get subtitle {
    if (weekday != null) return 'هر هفته جمعه';
    if (repeats > 1) return 'چند بار در روز';
    return 'هر روز';
  }
}

const reminderDefs = <ReminderDef>[
  ReminderDef(
    key: 'breakfast',
    title: 'صبحانه',
    body: 'وقت صبحانه است. بعد از خوردن، آن را در فیت‌لایف ثبت کنید.',
    icon: Icons.free_breakfast_outlined,
    defaultHour: 8,
    defaultMinute: 0,
    baseId: 100,
    defaultOn: true,
  ),
  ReminderDef(
    key: 'lunch',
    title: 'ناهار',
    body: 'وقت ناهار است. یادتان نرود سبزی و سالاد هم کنارش باشد.',
    icon: Icons.lunch_dining_outlined,
    defaultHour: 13,
    defaultMinute: 0,
    baseId: 110,
    defaultOn: true,
  ),
  ReminderDef(
    key: 'dinner',
    title: 'شام',
    body: 'وقت شام است. یک وعده سبک و کامل انتخاب کنید.',
    icon: Icons.dinner_dining_outlined,
    defaultHour: 19,
    defaultMinute: 30,
    baseId: 120,
    defaultOn: true,
  ),
  ReminderDef(
    key: 'snack',
    title: 'میان‌وعده',
    body: 'میان‌وعده سالم: میوه، ماست یا کمی مغز.',
    icon: Icons.apple_outlined,
    defaultHour: 16,
    defaultMinute: 30,
    baseId: 130,
  ),
  ReminderDef(
    key: 'water',
    title: 'نوشیدن آب',
    body: 'یک لیوان آب بنوشید و در فیت‌لایف ثبت کنید.',
    icon: Icons.water_drop_outlined,
    defaultHour: 9,
    defaultMinute: 30,
    baseId: 200,
    defaultOn: true,
    repeats: 5,
    everyMinutes: 120,
  ),
  ReminderDef(
    key: 'weight',
    title: 'ثبت وزن',
    body: 'صبح قبل از صبحانه وزن خود را ثبت کنید.',
    icon: Icons.monitor_weight_outlined,
    defaultHour: 7,
    defaultMinute: 30,
    baseId: 140,
  ),
  ReminderDef(
    key: 'symptoms',
    title: 'ثبت وضعیت کمر و پا',
    body: 'وضعیت درد کمر و پا و هر علامت تازه را ثبت کنید.',
    icon: Icons.healing_outlined,
    defaultHour: 21,
    defaultMinute: 0,
    baseId: 150,
    defaultOn: true,
  ),
  ReminderDef(
    key: 'posture',
    title: 'تغییر وضعیت بدن',
    body: 'مدتی است نشسته‌اید. اگر برایتان راحت است وضعیت بدن را عوض کنید.',
    icon: Icons.accessibility_new_rounded,
    defaultHour: 9,
    defaultMinute: 0,
    baseId: 300,
    repeats: 8,
    everyMinutes: 60,
  ),
  ReminderDef(
    key: 'activity',
    title: 'فعالیت تأییدشده',
    body: 'اگر پزشک یا فیزیوتراپیست فعالیتی را تأیید کرده، الان وقتش است.',
    icon: Icons.directions_walk_rounded,
    defaultHour: 17,
    defaultMinute: 30,
    baseId: 160,
  ),
  ReminderDef(
    key: 'weekly',
    title: 'گزارش هفتگی',
    body: 'گزارش هفته شما آماده است؛ وزن، کالری و وضعیت کمر را ببینید.',
    icon: Icons.insights_rounded,
    defaultHour: 20,
    defaultMinute: 0,
    baseId: 170,
    weekday: DateTime.friday,
  ),
];

class ReminderPrefs {
  final bool on;
  final TimeOfDay time;
  const ReminderPrefs(this.on, this.time);
}

class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    _setLocalZone();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _inited = true;
  }

  /// بدون بسته اضافه: یک منطقه زمانی پیدا می‌کنیم که اختلاف ساعتش با ساعت گوشی یکی باشد.
  static void _setLocalZone() {
    final offset = DateTime.now().timeZoneOffset;
    final now = DateTime.now().toUtc();
    tz.Location? found;
    // اولویت با تهران
    for (final name in const ['Asia/Tehran']) {
      final loc = tz.getLocation(name);
      if (loc.timeZone(now.millisecondsSinceEpoch).offset == offset.inMilliseconds) {
        found = loc;
      }
    }
    found ??= () {
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.timeZone(now.millisecondsSinceEpoch).offset == offset.inMilliseconds) {
          return loc;
        }
      }
      return null;
    }();
    tz.setLocalLocation(found ?? tz.UTC);
  }

  static Future<bool> requestPermission() async {
    await init();
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ok = await a?.requestNotificationsPermission();
    return ok ?? true;
  }

  static Future<bool> permissionGranted() async {
    await init();
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await a?.areNotificationsEnabled() ?? true;
  }

  // ---------- ذخیره/خواندن تنظیمات ----------
  static Future<Map<String, ReminderPrefs>> loadPrefs() async {
    final s = await AppDb.allSettings();
    final out = <String, ReminderPrefs>{};
    for (final d in reminderDefs) {
      final on = s['rem_${d.key}_on'] == null ? d.defaultOn : s['rem_${d.key}_on'] == '1';
      var t = TimeOfDay(hour: d.defaultHour, minute: d.defaultMinute);
      final raw = s['rem_${d.key}_time'];
      if (raw != null && raw.contains(':')) {
        final p = raw.split(':');
        final h = int.tryParse(p[0]);
        final m = int.tryParse(p[1]);
        if (h != null && m != null) t = TimeOfDay(hour: h, minute: m);
      }
      out[d.key] = ReminderPrefs(on, t);
    }
    return out;
  }

  static Future<void> savePref(String key, {bool? on, TimeOfDay? time}) async {
    final m = <String, String>{};
    if (on != null) m['rem_${key}_on'] = on ? '1' : '0';
    if (time != null) {
      m['rem_${key}_time'] =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    await AppDb.setSettings(m);
  }

  // ---------- زمان‌بندی ----------
  static tz.TZDateTime _nextTime(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (weekday != null) {
      while (t.weekday != weekday) {
        t = t.add(const Duration(days: 1));
      }
    }
    while (!t.isAfter(now)) {
      t = t.add(Duration(days: weekday != null ? 7 : 1));
    }
    return t;
  }

  static NotificationDetails _details(ReminderDef d) => NotificationDetails(
        android: AndroidNotificationDetails(
          'fitlife_${d.key}',
          d.title,
          channelDescription: 'یادآوری ${d.title}',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  static Future<void> cancelOne(ReminderDef d) async {
    await init();
    for (var i = 0; i < d.repeats; i++) {
      await _plugin.cancel(d.baseId + i);
    }
  }

  static Future<void> scheduleOne(ReminderDef d, TimeOfDay time) async {
    await init();
    await cancelOne(d);
    for (var i = 0; i < d.repeats; i++) {
      final total = time.hour * 60 + time.minute + i * d.everyMinutes;
      if (total >= 24 * 60) break;
      final when = _nextTime(total ~/ 60, total % 60, weekday: d.weekday);
      await _plugin.zonedSchedule(
        d.baseId + i,
        d.title,
        d.body,
        when,
        _details(d),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            d.weekday != null ? DateTimeComponents.dayOfWeekAndTime : DateTimeComponents.time,
      );
    }
  }

  /// همه یادآوری‌ها را مطابق تنظیمات ذخیره‌شده دوباره زمان‌بندی می‌کند
  static Future<void> rescheduleAll() async {
    await init();
    final prefs = await loadPrefs();
    for (final d in reminderDefs) {
      final p = prefs[d.key]!;
      if (p.on) {
        await scheduleOne(d, p.time);
      } else {
        await cancelOne(d);
      }
    }
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
