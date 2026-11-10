import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../data/menu_planner.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'food_sheets.dart';
import 'widgets.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final day = s.selectedDay;
    final t = s.dayTotals;
    final isToday = dateKey(day) == dateKey(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('رژیم غذایی',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PlanScreen())),
              icon: const Icon(Icons.event_note_rounded, size: 18),
              label: const Text('برنامه پیشنهادی'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => s.selectDay(day.subtract(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: day,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) s.selectDay(d);
                  },
                  child: Column(
                    children: [
                      Text(isToday ? 'امروز' : weekdayName(day),
                          style: TextStyle(fontSize: 12, color: C.muted(context))),
                      Text(jalaliShort(day),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => s.selectDay(day.add(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sum(context, 'کالری', '${fmt(t.kcal)}/${fmt(p.kcal)}', C.orange),
              _sum(context, 'پروتئین', '${fmt(t.protein)}g', C.blue),
              _sum(context, 'کربو', '${fmt(t.carbs)}g', C.green),
              _sum(context, 'چربی', '${fmt(t.fat)}g', C.purple),
            ],
          ),
        ),
        for (final m in mealKeys) _meal(context, s, m),
      ],
    );
  }

  Widget _sum(BuildContext c, String l, String v, Color col) => Column(
        children: [
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, color: col, fontSize: 14)),
          const SizedBox(height: 3),
          Text(l, style: TextStyle(fontSize: 11.5, color: C.muted(c))),
        ],
      );

  Widget _meal(BuildContext context, AppState s, String m) {
    final items = s.dayLogs.where((e) => e.meal == m).toList();
    final kcal = items.fold<double>(0, (a, b) => a + b.n.kcal);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(mealNames[m]!,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Text('${fmt(kcal)} kcal',
                    style: const TextStyle(color: C.orange, fontWeight: FontWeight.w700)),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('هنوز چیزی ثبت نشده',
                    style: TextStyle(fontSize: 12.5, color: C.muted(context))),
              ),
            for (final e in items)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: const TextStyle(fontSize: 14)),
                          Text('${fmt(e.grams)} گرم  •  ${fmt(e.n.kcal)} کیلوکالری',
                              style: TextStyle(fontSize: 12, color: C.muted(context))),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline_rounded, color: C.muted(context)),
                      onPressed: () => s.deleteLog(e.id),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => addFoodFlow(context, meal: m, day: s.selectedDay),
              icon: const Icon(Icons.add_rounded),
              label: const Text('افزودن غذا'),
            ),
          ],
        ),
      ),
    );
  }
}

/// برنامه غذایی پیشنهادی هفتگی + فهرست خرید
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const dayNames = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];
  late int day;

  @override
  void initState() {
    super.initState();
    day = (DateTime.now().weekday + 1) % 7;
  }

  DateTime _dateForIndex(int idx) {
    final now = dateOnly(DateTime.now());
    final todayIdx = (now.weekday + 1) % 7;
    return now.add(Duration(days: idx - todayIdx));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final plan = MenuPlanner.build(dayIndex: day, targetKcal: p.kcal, foods: s.foods);
    final tot = plan.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('برنامه پیشنهادی'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'فهرست خرید هفتگی',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => _showShopping(context, s, p),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(dayNames[i]),
                      selected: day == i,
                      onSelected: (_) => setState(() => day = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _t('کالری', fmt(tot.kcal), C.orange),
                _t('پروتئین', '${fmt(tot.protein)}g', C.blue),
                _t('کربو', '${fmt(tot.carbs)}g', C.green),
                _t('چربی', '${fmt(tot.fat)}g', C.purple),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'مقدارها بر اساس کالری هدف شما (${fmt(p.kcal)}) تنظیم شده‌اند. این یک پیشنهاد عمومی تغذیه‌ای است، نه نسخه پزشکی.',
            style: TextStyle(fontSize: 12, color: C.muted(context), height: 1.7),
          ),
          for (final m in mealKeys) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(mealNames[m]!,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                      Text('${fmt(plan.mealTotal(m).kcal)} kcal',
                          style: const TextStyle(color: C.orange, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final i in plan.meals[m] ?? const <ResolvedItem>[])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text(i.food.name, style: const TextStyle(fontSize: 13.5))),
                          Text('${fmt(i.grams)} گرم',
                              style: TextStyle(fontSize: 12.5, color: C.muted(context))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final target = _dateForIndex(day);
              final ok = await confirmDialog(
                context,
                'افزودن به ثبت غذا',
                'همه وعده‌های این برنامه به ثبت روز ${jalaliShort(target)} اضافه شود؟',
                ok: 'افزودن',
              );
              if (!ok || !context.mounted) return;
              for (final m in mealKeys) {
                for (final i in plan.meals[m] ?? const <ResolvedItem>[]) {
                  await s.addLog(meal: m, food: i.food, grams: i.grams, day: target);
                }
              }
              if (context.mounted) toast(context, 'برنامه به ثبت روز ${jalaliShort(target)} اضافه شد.');
            },
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: const Text('افزودن این روز به ثبت غذا'),
          ),
        ],
      ),
    );
  }

  Widget _t(String l, String v, Color c) => Column(
        children: [
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 14)),
          const SizedBox(height: 3),
          Text(l, style: TextStyle(fontSize: 11.5, color: C.muted(context))),
        ],
      );

  void _showShopping(BuildContext context, AppState s, Profile p) {
    final totals = <String, double>{};
    final cats = <String, String>{};
    for (var d = 0; d < 7; d++) {
      final plan = MenuPlanner.build(dayIndex: d, targetKcal: p.kcal, foods: s.foods);
      for (final l in plan.meals.values) {
        for (final i in l) {
          totals[i.food.name] = (totals[i.food.name] ?? 0) + i.grams;
          cats[i.food.name] = i.food.category;
        }
      }
    }
    final byCat = <String, List<MapEntry<String, double>>>{};
    totals.forEach((k, v) => byCat.putIfAbsent(cats[k]!, () => []).add(MapEntry(k, v)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.bg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (c) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('فهرست خرید هفتگی',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('مجموع مقدار مواد غذایی برنامه ۷ روزه (وزن خام/آماده‌خوری تقریبی)',
                style: TextStyle(fontSize: 12, color: C.muted(context))),
            for (final cat in byCat.keys) ...[
              SectionTitle(cat),
              for (final e in byCat[cat]!)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outline_blank_rounded, size: 20, color: C.green),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.key)),
                      Text(
                        e.value >= 1000
                            ? '${fmt(e.value / 1000, dec: 2)} کیلوگرم'
                            : '${fmt(e.value)} گرم',
                        style: TextStyle(color: C.muted(context), fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
