import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../data/foods_seed.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'widgets.dart';

/// انتخاب غذا از بانک غذایی (با جست‌وجو و دسته‌بندی)
Future<Food?> pickFood(BuildContext context) {
  return showModalBottomSheet<Food>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.bg(context),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (c) => const _PickerSheet(),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet();
  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String q = '';
  String? cat;

  @override
  Widget build(BuildContext context) {
    final foods = context.watch<AppState>().foods;
    final list = foods.where((f) {
      if (cat != null && f.category != cat) return false;
      if (q.trim().isNotEmpty && !f.name.contains(q.trim())) return false;
      return true;
    }).toList();
    final h = MediaQuery.of(context).size.height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: h,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: C.card2(context), borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => q = v),
                decoration: const InputDecoration(
                  hintText: 'جست‌وجوی غذا...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('همه', cat == null, () => setState(() => cat = null)),
                  for (final c in foodCategories)
                    _chip(c, cat == c, () => setState(() => cat = c)),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('غذایی پیدا نشد.\nمی‌توانید در «بانک غذا» غذای جدید اضافه کنید.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: C.muted(context))))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: list.length,
                      itemBuilder: (c, i) => FoodTile(
                        food: list[i],
                        onTap: () => Navigator.pop(context, list[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, bool sel, VoidCallback f) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(label: Text(t), selected: sel, onSelected: (_) => f()),
      );
}

class FoodTile extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;
  final Widget? trailing;
  const FoodTile({super.key, required this.food, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final n = food.per(food.servingG);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(food.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      if (food.estimated) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: C.orange.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('تخمینی',
                              style: TextStyle(fontSize: 10, color: C.orange)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.servingLabel} (${fmt(food.servingG)} گرم)  •  ${fmt(n.kcal)} کیلوکالری',
                    style: TextStyle(fontSize: 12, color: C.muted(context)),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.add_circle_outline_rounded, color: C.green),
          ],
        ),
      ),
    );
  }
}

/// انتخاب مقدار و وعده و ثبت
Future<bool> showPortionSheet(
  BuildContext context, {
  required Food food,
  String meal = 'lunch',
  DateTime? day,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.bg(context),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (c) => _PortionSheet(food: food, meal: meal, day: day),
  );
  return r ?? false;
}

class _PortionSheet extends StatefulWidget {
  final Food food;
  final String meal;
  final DateTime? day;
  const _PortionSheet({required this.food, required this.meal, this.day});
  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late TextEditingController grams;
  late String meal;

  @override
  void initState() {
    super.initState();
    meal = widget.meal;
    grams = TextEditingController(text: '${widget.food.servingG.round()}');
    grams.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    final g = parseNum(grams.text) ?? 0;
    final n = f.per(g);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 16, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (f.estimated)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('ارزش غذایی این مورد تخمینی است (غذای خانگی/مرکب).',
                  style: TextStyle(fontSize: 12, color: C.orange)),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final m in mealKeys)
                ChoiceChip(
                  label: Text(mealNames[m]!),
                  selected: meal == m,
                  onSelected: (_) => setState(() => meal = m),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'مقدار (گرم)'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text('${f.servingLabel} (${fmt(f.servingG)}g)'),
                onPressed: () => grams.text = '${f.servingG.round()}',
              ),
              ActionChip(
                label: Text('${fmt(f.servingG * 2)}g'),
                onPressed: () => grams.text = '${(f.servingG * 2).round()}',
              ),
              ActionChip(
                label: Text('نصف: ${fmt(f.servingG / 2)}g'),
                onPressed: () => grams.text = '${(f.servingG / 2).round()}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            color: C.card2(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _n('کالری', fmt(n.kcal), C.orange),
                _n('پروتئین', '${fmt(n.protein, dec: 1)}g', C.blue),
                _n('کربو', '${fmt(n.carbs, dec: 1)}g', C.green),
                _n('چربی', '${fmt(n.fat, dec: 1)}g', C.purple),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: g <= 0 || g > 3000
                ? null
                : () async {
                    await context.read<AppState>().addLog(
                        meal: meal, food: f, grams: g, day: widget.day);
                    if (context.mounted) Navigator.pop(context, true);
                  },
            child: const Text('ثبت در وعده'),
          ),
        ],
      ),
    );
  }

  Widget _n(String l, String v, Color c) => Column(
        children: [
          Text(v, style: TextStyle(fontWeight: FontWeight.w700, color: c, fontSize: 15)),
          const SizedBox(height: 2),
          Text(l, style: TextStyle(fontSize: 11, color: C.muted(context))),
        ],
      );
}

/// افزودن غذا: ابتدا انتخاب، سپس مقدار
Future<void> addFoodFlow(BuildContext context, {String meal = 'lunch', DateTime? day}) async {
  final f = await pickFood(context);
  if (f == null || !context.mounted) return;
  final ok = await showPortionSheet(context, food: f, meal: meal, day: day);
  if (ok && context.mounted) toast(context, '«${f.name}» ثبت شد.');
}
