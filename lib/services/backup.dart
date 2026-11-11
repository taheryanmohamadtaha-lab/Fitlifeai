import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/fa.dart';
import '../data/db.dart';
import '../data/models.dart';

/// پشتیبان‌گیری، بازیابی و خروجی گزارش
class BackupService {
  static const _magic = 'fitlife-backup';

  static Future<File> _tempFile(String name) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$name');
  }

  /// ساخت فایل پشتیبان و اشتراک‌گذاری (ذخیره در فایل‌ها، تلگرام، ایمیل و ...)
  static Future<void> createAndShare() async {
    final data = await AppDb.dumpAll();
    final doc = {
      'magic': _magic,
      'version': 1,
      'created': DateTime.now().toIso8601String(),
      'tables': data,
    };
    final stamp = dateKey(DateTime.now());
    final f = await _tempFile('fitlife-backup-$stamp.json');
    await f.writeAsString(jsonEncode(doc), flush: true);
    await Share.shareXFiles(
      [XFile(f.path, mimeType: 'application/json')],
      subject: 'پشتیبان فیت‌لایف',
      text: 'پشتیبان اطلاعات فیت‌لایف ($stamp)',
    );
  }

  /// بازیابی از فایل؛ در صورت موفقیت true برمی‌گرداند، اگر کاربر انصراف دهد null
  static Future<bool?> pickAndRestore() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    if (res == null || res.files.isEmpty || res.files.first.path == null) return null;
    final text = await File(res.files.first.path!).readAsString();
    final dynamic doc;
    try {
      doc = jsonDecode(text);
    } catch (_) {
      return false;
    }
    if (doc is! Map || doc['magic'] != _magic || doc['tables'] is! Map) return false;
    await AppDb.restoreAll(Map<String, dynamic>.from(doc['tables'] as Map));
    return true;
  }

  // ---------- CSV (قابل باز شدن در Excel) ----------
  static String _cell(Object? v) {
    final s = (v ?? '').toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _row(List<Object?> cols) => cols.map(_cell).join(',');

  static Future<void> exportCsv() async {
    final weights = await AppDb.weights();
    final pains = await AppDb.pains();
    final foods = await AppDb.allFoodLog();

    final b = StringBuffer('﻿');
    b.writeln('وزن و اندازه‌ها');
    b.writeln(_row(['تاریخ', 'وزن (kg)', 'دور شکم (cm)']));
    for (final w in weights) {
      b.writeln(_row([w.date, w.kg, w.waist]));
    }
    b.writeln();
    b.writeln('ثبت غذا');
    b.writeln(_row(['تاریخ', 'وعده', 'غذا', 'گرم', 'کالری', 'پروتئین', 'کربوهیدرات', 'چربی', 'فیبر']));
    for (final r in foods) {
      b.writeln(_row([
        r['date'],
        mealNames[r['meal']] ?? r['meal'],
        r['name'],
        _n(r['grams']),
        _n(r['kcal']),
        _n(r['protein']),
        _n(r['carbs']),
        _n(r['fat']),
        _n(r['fiber']),
      ]));
    }
    b.writeln();
    b.writeln('درد کمر و پا');
    b.writeln(_row(['تاریخ', 'ساعت', 'کمر', 'پای راست', 'پای چپ', 'محل انتشار', 'بی‌حسی', 'گزگز', 'ضعف پا', 'بی‌حسی زینی', 'اختلال ادرار/مدفوع', 'فعالیت‌ها', 'یادداشت']));
    for (final p in pains) {
      b.writeln(_row([
        p.date,
        p.time,
        p.back,
        p.rleg,
        p.lleg,
        p.spread,
        p.numb ? 'بله' : '',
        p.tingle ? 'بله' : '',
        p.weak ? 'بله' : '',
        p.saddle ? 'بله' : '',
        p.bladder ? 'بله' : '',
        p.activities,
        p.note,
      ]));
    }
    final f = await _tempFile('fitlife-report-${dateKey(DateTime.now())}.csv');
    await f.writeAsString(b.toString(), flush: true);
    await Share.shareXFiles([XFile(f.path, mimeType: 'text/csv')], subject: 'گزارش فیت‌لایف');
  }

  static String _n(Object? v) => v is num ? v.toStringAsFixed(1) : '${v ?? ''}';

  /// متن خلاصه برای نمایش به پزشک
  static Future<void> shareText(String subject, String text) async {
    await Share.share(text, subject: subject);
  }
}
