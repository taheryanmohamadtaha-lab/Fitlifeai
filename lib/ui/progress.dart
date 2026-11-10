import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/calc.dart';
import '../core/fa.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'widgets.dart';

/// نمودار وزن
class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double goal;
  final bool compact;
  const WeightChart({super.key, required this.entries, required this.goal, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Center(
        child: Text('برای دیدن نمودار، حداقل دو وزن ثبت کنید.',
            style: TextStyle(color: C.muted(context), fontSize: 13)),
      );
    }
    final first = parseKey(entries.first.date);
    double x(String d) => parseKey(d).difference(first).inDays.toDouble();
    final spots = [for (final e in entries) FlSpot(x(e.date), e.kg)];
    final ys = entries.map((e) => e.kg).toList()..add(goal);
    var minY = ys.reduce((a, b) => a < b ? a : b) - 1.5;
    var maxY = ys.reduce((a, b) => a > b ? a : b) + 1.5;
    if (maxY - minY < 4) maxY = minY + 4;
    final maxX = spots.last.x == 0 ? 1.0 : spots.last.x;
    final muted = C.muted(context);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: muted.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(faNum(v.round()),
                  style: TextStyle(fontSize: 10, color: muted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 26,
              interval: (maxX / 4).clamp(1, 100000).toDouble(),
              getTitlesWidget: (v, meta) {
                final d = first.add(Duration(days: v.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(jalaliShort(d), style: TextStyle(fontSize: 9.5, color: muted)),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: goal,
            color: C.green.withOpacity(0.7),
            strokeWidth: 1.5,
            dashArray: [6, 5],
          ),
        ]),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (items) => [
              for (final i in items)
                LineTooltipItem(
                  '${fmt(i.y, dec: 1)} kg\n${jalaliShort(first.add(Duration(days: i.x.round())))}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: C.orange,
            barWidth: 3,
            dotData: FlDotData(show: !compact && spots.length <= 40),
            belowBarData: BarAreaData(
              show: true,
              color: C.orange.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final weightCtl = TextEditingController();
  final waistCtl = TextEditingController();
  int range = 0; // ۰: ۷ روز، ۱: ۳۰ روز، ۲: همه

  @override
  void dispose() {
    weightCtl.dispose();
    waistCtl.dispose();
    super.dispose();
  }

  List<WeightEntry> _filtered(List<WeightEntry> all) {
    if (range == 2) return all;
    final days = range == 0 ? 7 : 30;
    final from = dateOnly(DateTime.now()).subtract(Duration(days: days));
    final l = all.where((e) => !parseKey(e.date).isBefore(from)).toList();
    return l.length >= 2 ? l : all.length >= 2 ? all.sublist(all.length - 2) : all;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final cur = s.currentWeight;
    final weekly = Calc.weeklyAverages(s.weights);
    final tdee = s.tdee;
    final rate = Calc.weeklyLossKg(tdee: tdee, kcal: p.kcal);
    final remaining = cur - p.goalWeight;
    final weeks = Calc.weeksToGoal(remainingKg: remaining, weeklyKg: rate);
    final miles = Calc.milestones(p.startWeight, p.goalWeight);

    // تغییر نسبت به آخرین ثبت قبلی
    String? delta;
    if (s.weights.length >= 2) {
      final d = s.weights.last.kg - s.weights[s.weights.length - 2].kg;
      delta = '${d > 0 ? '+' : ''}${fmt(d, dec: 1)} kg نسبت به ثبت قبلی';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text('پیشرفت', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ثبت وزن امروز',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'وزن (kg)', hintText: fmt(cur, dec: 1)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: waistCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'دور شکم (cm)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () async {
                  final w = parseNum(weightCtl.text);
                  if (w == null || w < 30 || w > 300) {
                    toast(context, 'وزن معتبر وارد کنید.');
                    return;
                  }
                  final wa = parseNum(waistCtl.text);
                  await s.saveWeight(DateTime.now(), w, wa);
                  weightCtl.clear();
                  waistCtl.clear();
                  if (context.mounted) {
                    FocusScope.of(context).unfocus();
                    toast(context, 'وزن ثبت شد.');
                  }
                },
                child: const Text('ثبت'),
              ),
              if (delta != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(delta, style: TextStyle(fontSize: 12, color: C.muted(context))),
                ),
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
                    child: Text('نمودار وزن',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('هفته')),
                      ButtonSegment(value: 1, label: Text('ماه')),
                      ButtonSegment(value: 2, label: Text('همه')),
                    ],
                    selected: {range},
                    onSelectionChanged: (v) => setState(() => range = v.first),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(height: 210, child: WeightChart(entries: _filtered(s.weights), goal: p.goalWeight)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(width: 14, height: 3, color: C.green),
                  const SizedBox(width: 6),
                  Text('خط هدف (${fmt(p.goalWeight, dec: 1)} kg)',
                      style: TextStyle(fontSize: 11.5, color: C.muted(context))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مرحله‌های هدف',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              for (var i = 0; i < miles.length; i++)
                _mile(context, i, miles[i], cur, p),
              const SizedBox(height: 8),
              Text(
                weeks == null
                    ? 'با کالری فعلی کسری انرژی وجود ندارد؛ هدف کالری را در «من» بررسی کنید.'
                    : weeks == 0
                        ? 'به هدف رسیده‌اید 🎉'
                        : 'با روند کالری فعلی (≈ ${fmt(rate, dec: 2)} کیلوگرم در هفته) حدود ${fmt(weeks)} هفته تا هدف مانده است. این فقط یک تخمین است و روند واقعی ممکن است متفاوت باشد.',
                style: TextStyle(fontSize: 12, color: C.muted(context), height: 1.8),
              ),
            ],
          ),
        ),
        if (weekly.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('میانگین هفتگی',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                for (var i = weekly.length - 1; i >= 0 && i >= weekly.length - 8; i--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text('هفته ${jalaliShort(weekly[i].start)}')),
                        Text('${fmt(weekly[i].avg, dec: 1)} kg',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 62,
                          child: Text(
                            i == 0
                                ? '—'
                                : '${weekly[i].avg - weekly[i - 1].avg > 0 ? '+' : ''}${fmt(weekly[i].avg - weekly[i - 1].avg, dec: 1)}',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: i == 0
                                  ? C.muted(context)
                                  : (weekly[i].avg - weekly[i - 1].avg <= 0 ? C.green : C.orange),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سوابق',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              if (s.weights.isEmpty)
                Text('هنوز چیزی ثبت نشده.', style: TextStyle(color: C.muted(context))),
              for (final e in s.weights.reversed.take(30))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(jalaliFull(parseKey(e.date)))),
                      Text(
                        '${fmt(e.kg, dec: 1)} kg${e.waist != null ? '  •  شکم ${fmt(e.waist!, dec: 1)}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.delete_outline_rounded, size: 20, color: C.muted(context)),
                        onPressed: () async {
                          final ok = await confirmDialog(context, 'حذف ثبت وزن',
                              'ثبت ${jalaliFull(parseKey(e.date))} حذف شود؟',
                              ok: 'حذف', danger: true);
                          if (ok) s.deleteWeight(e.date);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'نوسان روزانه وزن طبیعی است؛ به میانگین هفتگی و روند کلی نگاه کنید، نه یک عدد.',
          style: TextStyle(fontSize: 12, color: C.muted(context), height: 1.7),
        ),
      ],
    );
  }

  Widget _mile(BuildContext context, int i, double w, double cur, Profile p) {
    final reached = cur <= w + 0.001;
    final isStart = i == 0;
    final isGoal = w == p.goalWeight && i != 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: reached ? C.green : C.muted(context),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isStart
                  ? 'شروع'
                  : isGoal
                      ? 'هدف نهایی'
                      : 'مرحله ${faNum(i)}',
            ),
          ),
          Text('${fmt(w, dec: 1)} kg',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: reached ? C.green : C.text(context))),
        ],
      ),
    );
  }
}
