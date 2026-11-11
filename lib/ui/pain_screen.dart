import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../services/backup.dart';
import '../state/app_state.dart';
import 'widgets.dart';

const painActivities = [
  'پیاده‌روی کوتاه',
  'نشستن طولانی',
  'ایستادن طولانی',
  'کارهای خانه',
  'رانندگی',
  'بلند کردن وسیله',
  'خم شدن',
  'استراحت زیاد',
  'خواب بد',
];

const spreadOptions = [
  'منتشر نمی‌شود',
  'باسن',
  'پشت ران',
  'ساق پا',
  'کف پا / انگشتان',
];

/// پیام هشدار فوری
const emergencyText =
    'ضعف جدید یا رو‌به‌پیشرفت پا، بی‌حسی ناحیه زینی (اطراف مقعد و بین پاها) یا اختلال جدید در کنترل ادرار و مدفوع '
    'می‌تواند نشانه یک وضعیت اورژانسی باشد.\n\n'
    'لطفاً همین حالا به اورژانس یا نزدیک‌ترین مرکز درمانی مراجعه کنید و منتظر بهتر شدن نمانید.';

Future<void> showEmergencyDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: C.red, size: 42),
      title: const Text('مراجعه فوری به اورژانس'),
      content: const Text(emergencyText, style: TextStyle(height: 1.8)),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: C.red),
          onPressed: () => Navigator.pop(c),
          child: const Text('متوجه شدم'),
        ),
      ],
    ),
  );
}

class PainScreen extends StatefulWidget {
  const PainScreen({super.key});

  @override
  State<PainScreen> createState() => _PainScreenState();
}

class _PainScreenState extends State<PainScreen> {
  double back = 0, rleg = 0, lleg = 0;
  String spread = spreadOptions.first;
  bool numb = false, tingle = false, weak = false, saddle = false, bladder = false;
  final Set<String> acts = {};
  final note = TextEditingController();
  int range = 30;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      back = 0;
      rleg = 0;
      lleg = 0;
      spread = spreadOptions.first;
      numb = tingle = weak = saddle = bladder = false;
      acts.clear();
      note.clear();
    });
  }

  Future<void> _save(AppState s) async {
    final now = DateTime.now();
    final prev = s.pains.isEmpty ? null : s.pains.last;
    final e = PainEntry(
      date: dateKey(dateOnly(now)),
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      back: back.round(),
      rleg: rleg.round(),
      lleg: lleg.round(),
      spread: spread,
      numb: numb,
      tingle: tingle,
      weak: weak,
      saddle: saddle,
      bladder: bladder,
      activities: acts.join('،'),
      note: note.text.trim(),
    );
    await s.addPain(e);
    if (!mounted) return;
    final emergency = e.emergency;
    final worse = prev != null &&
        (e.back > prev.back + 1 ||
            e.rleg > prev.rleg + 1 ||
            e.lleg > prev.lleg + 1 ||
            (e.spread != prev.spread && e.spread != spreadOptions.first));
    final highPain = e.back >= 8 || e.rleg >= 8 || e.lleg >= 8;
    _reset();
    if (emergency) {
      await showEmergencyDialog(context);
    } else if (e.numb || e.tingle || worse || highPain) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.info_outline_rounded, color: C.orange, size: 38),
          title: const Text('ثبت شد؛ این تغییر را به پزشک بگویید'),
          content: Text(
            [
              if (worse) '• درد یا انتشار آن نسبت به ثبت قبلی بیشتر شده است.',
              if (e.numb) '• بی‌حسی ثبت شد.',
              if (e.tingle) '• گزگز ثبت شد.',
              if (highPain) '• شدت درد زیاد است.',
              '',
              'اگر درد بیشتر می‌شود، هر نوع فعالیت یا حرکت را متوقف کنید و در اولین فرصت با پزشک یا فیزیوتراپیست مشورت کنید. '
                  'می‌توانید از دکمه «خلاصه برای پزشک» استفاده کنید.',
            ].join('\n'),
            style: const TextStyle(height: 1.8),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('باشه')),
          ],
        ),
      );
    } else {
      toast(context, 'ثبت شد.');
    }
  }

  String _summary(AppState s) {
    final from = dateKey(dateOnly(DateTime.now()).subtract(const Duration(days: 14)));
    final l = s.pains.where((e) => e.date.compareTo(from) >= 0).toList();
    final b = StringBuffer('خلاصه ۱۴ روز اخیر درد کمر و پا (ثبت‌شده توسط خود کاربر در اپ فیت‌لایف)\n');
    b.writeln('این متن تشخیص پزشکی نیست.\n');
    if (l.isEmpty) b.writeln('ثبتی وجود ندارد.');
    for (final e in l) {
      b.write('${jalaliShort(parseKey(e.date))} ${e.time} — کمر ${e.back}/۱۰، پای راست ${e.rleg}، پای چپ ${e.lleg}');
      if (e.spread != spreadOptions.first) b.write('، انتشار: ${e.spread}');
      final flags = [
        if (e.numb) 'بی‌حسی',
        if (e.tingle) 'گزگز',
        if (e.weak) 'ضعف پا',
        if (e.saddle) 'بی‌حسی زینی',
        if (e.bladder) 'اختلال ادرار/مدفوع',
      ];
      if (flags.isNotEmpty) b.write('، علائم: ${flags.join('، ')}');
      if (e.activities.isNotEmpty) b.write('، فعالیت‌ها: ${e.activities}');
      if (e.note.isNotEmpty) b.write('، یادداشت: ${e.note}');
      b.writeln();
    }
    return faNumText(b.toString());
  }

  String faNumText(String s) => faNum(s);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final from = dateKey(dateOnly(DateTime.now()).subtract(Duration(days: range)));
    final list = s.pains.where((e) => e.date.compareTo(from) >= 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('پایش درد کمر و پا'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          if (s.recentEmergency != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                color: C.red.withOpacity(0.16),
                onTap: () => showEmergencyDialog(context),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: C.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'در ۳ روز اخیر علامت هشدار ثبت کرده‌اید. اگر هنوز بررسی نشده، فوراً به اورژانس مراجعه کنید.',
                        style: TextStyle(fontSize: 13, height: 1.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ثبت وضعیت الان',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                _slider('درد کمر', back, C.orange, (v) => setState(() => back = v)),
                _slider('درد پای راست', rleg, C.blue, (v) => setState(() => rleg = v)),
                _slider('درد پای چپ', lleg, C.purple, (v) => setState(() => lleg = v)),
                const SizedBox(height: 6),
                Text('محل انتشار درد',
                    style: TextStyle(fontSize: 13, color: C.muted(context))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final o in spreadOptions)
                      ChoiceChip(
                        label: Text(o),
                        selected: spread == o,
                        onSelected: (_) => setState(() => spread = o),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('علائم عصبی',
                    style: TextStyle(fontSize: 13, color: C.muted(context))),
                _check('بی‌حسی', numb, (v) => setState(() => numb = v)),
                _check('گزگز', tingle, (v) => setState(() => tingle = v)),
                _check('ضعف پا (جدید یا بدتر شونده)', weak, (v) => setState(() => weak = v),
                    danger: true),
                _check('بی‌حسی ناحیه زینی (اطراف مقعد / بین پاها)', saddle,
                    (v) => setState(() => saddle = v),
                    danger: true),
                _check('اختلال جدید در کنترل ادرار یا مدفوع', bladder,
                    (v) => setState(() => bladder = v),
                    danger: true),
                const SizedBox(height: 10),
                Text('امروز چه کارهایی کردید؟',
                    style: TextStyle(fontSize: 13, color: C.muted(context))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final a in painActivities)
                      FilterChip(
                        label: Text(a),
                        selected: acts.contains(a),
                        onSelected: (v) => setState(() {
                          v ? acts.add(a) : acts.remove(a);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'یادداشت (اختیاری)'),
                ),
                const SizedBox(height: 14),
                FilledButton(onPressed: () => _save(s), child: const Text('ثبت')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('روند درد',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: 7, label: Text('هفته')),
                        ButtonSegment(value: 30, label: Text('ماه')),
                        ButtonSegment(value: 90, label: Text('۳ ماه')),
                      ],
                      selected: {range},
                      onSelectionChanged: (v) => setState(() => range = v.first),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(height: 200, child: _PainChart(entries: list, days: range)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  children: [
                    _legend('کمر', C.orange),
                    _legend('پای راست', C.blue),
                    _legend('پای چپ', C.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _activityInsights(context, list),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => BackupService.shareText('خلاصه درد کمر و پا', _summary(s)),
            icon: const Icon(Icons.share_rounded),
            label: const Text('خلاصه برای پزشک'),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سوابق اخیر',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                if (s.pains.isEmpty)
                  Text('هنوز چیزی ثبت نشده.', style: TextStyle(color: C.muted(context))),
                for (final e in s.pains.reversed.take(20)) _entryTile(context, s, e),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'این بخش فقط برای ثبت و پیگیری است و بیماری تشخیص نمی‌دهد یا درمان تجویز نمی‌کند. '
            'اگر درد یا علائم عصبی بیشتر شد، فعالیت را متوقف کنید و با پزشک مشورت کنید.',
            style: TextStyle(fontSize: 12, color: C.muted(context), height: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double v, Color color, ValueChanged<double> f) => Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${faNum(v.round())} از ۱۰',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          Slider(value: v, min: 0, max: 10, divisions: 10, activeColor: color, onChanged: f),
        ],
      );

  Widget _check(String t, bool v, ValueChanged<bool> f, {bool danger = false}) =>
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: danger ? C.red : C.green,
        value: v,
        onChanged: (x) => f(x ?? false),
        title: Text(t,
            style: TextStyle(
                fontSize: 13.5, color: danger && v ? C.red : null)),
      );

  Widget _legend(String t, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 4, color: c),
          const SizedBox(width: 6),
          Text(t, style: TextStyle(fontSize: 11.5, color: C.muted(context))),
        ],
      );

  Widget _entryTile(BuildContext context, AppState s, PainEntry e) {
    final flags = [
      if (e.numb) 'بی‌حسی',
      if (e.tingle) 'گزگز',
      if (e.weak) 'ضعف پا',
      if (e.saddle) 'بی‌حسی زینی',
      if (e.bladder) 'اختلال ادرار/مدفوع',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${jalaliShort(parseKey(e.date))}  ${faNum(e.time)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'کمر ${faNum(e.back)}  •  راست ${faNum(e.rleg)}  •  چپ ${faNum(e.lleg)}'
                  '${e.spread == spreadOptions.first ? '' : '  •  ${e.spread}'}',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context)),
                ),
                if (flags.isNotEmpty)
                  Text(flags.join('، '),
                      style: TextStyle(
                          fontSize: 12.5,
                          color: e.emergency ? C.red : C.orange,
                          fontWeight: FontWeight.w700)),
                if (e.activities.isNotEmpty)
                  Text(e.activities,
                      style: TextStyle(fontSize: 12, color: C.muted(context))),
                if (e.note.isNotEmpty)
                  Text(e.note, style: TextStyle(fontSize: 12, color: C.muted(context))),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: C.muted(context)),
            onPressed: () async {
              final ok = await confirmDialog(context, 'حذف ثبت', 'این ثبت حذف شود؟',
                  ok: 'حذف', danger: true);
              if (ok) s.deletePain(e.id);
            },
          ),
        ],
      ),
    );
  }

  /// میانگین درد کمر در ثبت‌هایی که هر فعالیت در آن‌ها علامت خورده، در مقایسه با بقیه
  Widget _activityInsights(BuildContext context, List<PainEntry> l) {
    if (l.length < 6) {
      return AppCard(
        child: Text(
          'ارتباط فعالیت‌ها با درد: بعد از حدود ۶ ثبت (با علامت‌زدن فعالیت‌ها) اینجا نمایش داده می‌شود.',
          style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
        ),
      );
    }
    final overall = l.map((e) => e.back).reduce((a, b) => a + b) / l.length;
    final rows = <MapEntry<String, double>>[];
    for (final a in painActivities) {
      final with_ = l.where((e) => e.activityList.contains(a)).toList();
      if (with_.length < 2) continue;
      final avg = with_.map((e) => e.back).reduce((a, b) => a + b) / with_.length;
      rows.add(MapEntry(a, avg - overall));
    }
    rows.sort((a, b) => b.value.compareTo(a.value));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('فعالیت‌ها و درد کمر',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('میانگین کلی درد کمر: ${fmt(overall, dec: 1)} از ۱۰',
              style: TextStyle(fontSize: 12.5, color: C.muted(context))),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text('هنوز برای هیچ فعالیتی دست‌کم دو ثبت وجود ندارد.',
                style: TextStyle(fontSize: 12.5, color: C.muted(context))),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(r.key, style: const TextStyle(fontSize: 13.5))),
                  Text(
                    '${r.value > 0 ? '+' : ''}${fmt(r.value, dec: 1)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: r.value > 0.3
                          ? C.red
                          : r.value < -0.3
                              ? C.green
                              : C.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'عدد = تفاوت میانگین درد کمر در ثبت‌هایی که این فعالیت را علامت زده‌اید با میانگین کلی. '
            'این فقط یک همبستگی ساده از ثبت‌های خودتان است، نه تشخیص علت؛ برای تصمیم درباره فعالیت‌ها با پزشک یا فیزیوتراپیست صحبت کنید.',
            style: TextStyle(fontSize: 11.5, color: C.muted(context), height: 1.8),
          ),
        ],
      ),
    );
  }
}

class _PainChart extends StatelessWidget {
  final List<PainEntry> entries;
  final int days;
  const _PainChart({required this.entries, required this.days});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Center(
        child: Text('برای دیدن نمودار، حداقل دو ثبت لازم است.',
            style: TextStyle(color: C.muted(context), fontSize: 13)),
      );
    }
    final start = dateOnly(DateTime.now()).subtract(Duration(days: days));
    double x(PainEntry e) => parseKey(e.date).difference(start).inHours / 24.0;
    List<FlSpot> spots(int Function(PainEntry) f) =>
        [for (final e in entries) FlSpot(x(e), f(e).toDouble())];
    final muted = C.muted(context);
    LineChartBarData line(List<FlSpot> sp, Color c) => LineChartBarData(
          spots: sp,
          isCurved: true,
          curveSmoothness: 0.2,
          preventCurveOverShooting: true,
          color: c,
          barWidth: 2.6,
          dotData: FlDotData(show: sp.length <= 20),
        );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: days.toDouble(),
        minY: 0,
        maxY: 10,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: muted.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (v, m) =>
                  Text(faNum(v.round()), style: TextStyle(fontSize: 10, color: muted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (days / 3).floorToDouble().clamp(1, 1000).toDouble(),
              getTitlesWidget: (v, m) {
                final d = start.add(Duration(days: v.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(jalaliShort(d), style: TextStyle(fontSize: 9.5, color: muted)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          line(spots((e) => e.back), C.orange),
          line(spots((e) => e.rleg), C.blue),
          line(spots((e) => e.lleg), C.purple),
        ],
      ),
    );
  }
}
