import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../data/db.dart';
import '../services/backup.dart';
import '../state/app_state.dart';
import 'widgets.dart';

class _Report {
  final List<Map<String, Object?>> days;
  final double avgWater;
  final int waterDays;
  const _Report(this.days, this.avgWater, this.waterDays);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int range = 7;
  late Future<_Report> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_Report> _load() async {
    final from = dateKey(dateOnly(DateTime.now()).subtract(Duration(days: range - 1)));
    final days = await AppDb.dailyTotals(from);
    final water = await AppDb.waterFrom(from);
    double sum = 0;
    for (final w in water) {
      sum += (w['ml'] as num).toDouble();
    }
    return _Report(days, water.isEmpty ? 0 : sum / water.length, water.length);
  }

  void _set(int r) {
    setState(() {
      range = r;
      future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final from = dateKey(dateOnly(DateTime.now()).subtract(Duration(days: range - 1)));

    final w = s.weights.where((e) => e.date.compareTo(from) >= 0).toList();
    final weightChange = w.length >= 2 ? w.last.kg - w.first.kg : null;
    final pains = s.pains.where((e) => e.date.compareTo(from) >= 0).toList();
    final avgBack = pains.isEmpty
        ? null
        : pains.map((e) => e.back).reduce((a, b) => a + b) / pains.length;
    final flagged = pains.where((e) => e.numb || e.tingle || e.emergency).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'خروجی Excel (CSV)',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () async {
              try {
                await BackupService.exportCsv();
              } catch (_) {
                if (context.mounted) toast(context, 'ساخت خروجی ممکن نشد.');
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<_Report>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: C.green));
          }
          final r = snap.data!;
          final days = r.days;
          final kcals = [for (final d in days) (d['kcal'] as num).toDouble()];
          final avgKcal = kcals.isEmpty ? 0.0 : kcals.reduce((a, b) => a + b) / kcals.length;
          double avgOf(String k) => days.isEmpty
              ? 0
              : days.map((d) => (d[k] as num).toDouble()).reduce((a, b) => a + b) / days.length;
          final onTarget = kcals.where((k) => k >= p.kcal * 0.85 && k <= p.kcal * 1.1).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Center(
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 7, label: Text('۷ روز')),
                    ButtonSegment(value: 30, label: Text('۳۰ روز')),
                    ButtonSegment(value: 90, label: Text('۹۰ روز')),
                  ],
                  selected: {range},
                  onSelectionChanged: (v) => _set(v.first),
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('وزن',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    _kv(context, 'وزن فعلی', '${fmt(s.currentWeight, dec: 1)} kg'),
                    _kv(context, 'کاهش از شروع', '${fmt(s.lostSoFar, dec: 1)} kg'),
                    _kv(
                      context,
                      'تغییر در این بازه',
                      weightChange == null
                          ? 'داده کافی نیست'
                          : '${weightChange > 0 ? '+' : ''}${fmt(weightChange, dec: 1)} kg',
                    ),
                    if (weightChange != null && range >= 7)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'میانگین: ${fmt(weightChange / range * 7, dec: 2)} کیلوگرم در هفته',
                          style: TextStyle(fontSize: 12, color: C.muted(context)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تغذیه',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    _kv(context, 'روزهای ثبت‌شده', '${fmt(days.length)} از ${fmt(range)}'),
                    _kv(context, 'میانگین کالری', '${fmt(avgKcal)} از ${fmt(p.kcal)}'),
                    _kv(context, 'روزهای نزدیک به هدف', fmt(onTarget)),
                    _kv(context, 'میانگین پروتئین', '${fmt(avgOf('protein'))} g'),
                    _kv(context, 'میانگین کربوهیدرات', '${fmt(avgOf('carbs'))} g'),
                    _kv(context, 'میانگین چربی', '${fmt(avgOf('fat'))} g'),
                    _kv(
                        context,
                        'میانگین آب',
                        r.waterDays == 0 ? '—' : '${fmt(r.avgWater)} از ${fmt(p.waterMl)} ml'),
                    if (days.length >= 2) ...[
                      const SizedBox(height: 16),
                      SizedBox(height: 170, child: _KcalChart(days: days, target: p.kcal, range: range)),
                      const SizedBox(height: 4),
                      Text('خط سبز = کالری هدف',
                          style: TextStyle(fontSize: 11.5, color: C.muted(context))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('کمر و پا',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    _kv(context, 'تعداد ثبت‌ها', fmt(pains.length)),
                    _kv(context, 'میانگین درد کمر',
                        avgBack == null ? '—' : '${fmt(avgBack, dec: 1)} از ۱۰'),
                    _kv(context, 'ثبت‌های دارای بی‌حسی/گزگز/هشدار', fmt(flagged)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await BackupService.exportCsv();
                  } catch (_) {
                    if (context.mounted) toast(context, 'ساخت خروجی ممکن نشد.');
                  }
                },
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('خروجی Excel (CSV) از همه اطلاعات'),
              ),
              const SizedBox(height: 10),
              Text(
                'فایل CSV را می‌توانید در Excel یا Google Sheets باز کنید.',
                style: TextStyle(fontSize: 12, color: C.muted(context)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: 13, color: C.muted(context)))),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _KcalChart extends StatelessWidget {
  final List<Map<String, Object?>> days;
  final int target;
  final int range;
  const _KcalChart({required this.days, required this.target, required this.range});

  @override
  Widget build(BuildContext context) {
    final start = dateOnly(DateTime.now()).subtract(Duration(days: range - 1));
    final muted = C.muted(context);
    final groups = <BarChartGroupData>[];
    var maxY = target * 1.3;
    for (final d in days) {
      final date = parseKey(d['date'] as String);
      final idx = date.difference(start).inDays;
      final k = (d['kcal'] as num).toDouble();
      if (k * 1.1 > maxY) maxY = k * 1.1;
      groups.add(BarChartGroupData(x: idx, barRods: [
        BarChartRodData(
          toY: k,
          width: range <= 7 ? 16 : (range <= 30 ? 6 : 2.5),
          color: k > target * 1.1 ? C.orange : C.green,
          borderRadius: BorderRadius.circular(3),
        ),
      ]));
    }
    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        barGroups: groups,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: muted.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
              y: target.toDouble(),
              color: C.green.withOpacity(0.8),
              strokeWidth: 1.5,
              dashArray: [6, 5]),
        ]),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, m) => Text(faNum(v.round()),
                  style: TextStyle(fontSize: 9.5, color: muted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (range / 3).floorToDouble().clamp(1, 1000).toDouble(),
              getTitlesWidget: (v, m) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(jalaliShort(start.add(Duration(days: v.round()))),
                    style: TextStyle(fontSize: 9.5, color: muted)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
