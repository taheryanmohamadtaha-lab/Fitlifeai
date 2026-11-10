import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../data/foods_seed.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'food_sheets.dart';
import 'widgets.dart';

class FoodBankScreen extends StatefulWidget {
  const FoodBankScreen({super.key});

  @override
  State<FoodBankScreen> createState() => _FoodBankScreenState();
}

class _FoodBankScreenState extends State<FoodBankScreen> {
  String q = '';
  String? cat;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.foods.where((f) {
      if (cat != null && f.category != cat) return false;
      if (q.trim().isNotEmpty && !f.name.contains(q.trim())) return false;
      return true;
    }).toList();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('بانک غذا',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  Text('${fmt(s.foods.length)} مورد',
                      style: TextStyle(color: C.muted(context), fontSize: 12.5)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: const InputDecoration(
                  hintText: 'جست‌وجوی غذا...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final f = list[i];
                  return FoodTile(
                    food: f,
                    trailing: Icon(Icons.chevron_left_rounded, color: C.muted(context)),
                    onTap: () => _details(context, f),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: C.green,
            foregroundColor: Colors.white,
            onPressed: () => _addCustom(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('غذای جدید'),
          ),
        ),
      ],
    );
  }

  Widget _chip(String t, bool sel, VoidCallback f) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(label: Text(t), selected: sel, onSelected: (_) => f()),
      );

  void _details(BuildContext context, Food f) {
    final n = f.per(f.servingG);
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(f.category, style: TextStyle(color: C.muted(context), fontSize: 12.5)),
            if (f.estimated)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('ارزش غذایی این مورد تخمینی است.',
                    style: TextStyle(color: C.orange, fontSize: 12.5)),
              ),
            const SizedBox(height: 14),
            _table(context, 'در ۱۰۰ گرم', f.per(100)),
            const SizedBox(height: 10),
            _table(context, '${f.servingLabel} (${fmt(f.servingG)} گرم)', n),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final today = DateTime.now();
                      final ok = await showPortionSheet(context,
                          food: f, meal: _guessMeal(), day: today);
                      if (ok && context.mounted) toast(context, 'برای امروز ثبت شد.');
                    },
                    child: const Text('ثبت برای امروز'),
                  ),
                ),
                if (f.custom) ...[
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () async {
                      final ok = await confirmDialog(
                          context, 'حذف غذا', '«${f.name}» از بانک غذا حذف شود؟',
                          ok: 'حذف', danger: true);
                      if (ok && context.mounted) {
                        await context.read<AppState>().deleteCustomFood(f.id!);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: C.red),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _guessMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return 'breakfast';
    if (h < 16) return 'lunch';
    if (h < 18) return 'snack';
    return 'dinner';
  }

  Widget _table(BuildContext context, String title, Nutr n) => AppCard(
        color: C.card2(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _cell('کالری', fmt(n.kcal), C.orange),
                _cell('پروتئین', fmt(n.protein, dec: 1), C.blue),
                _cell('کربو', fmt(n.carbs, dec: 1), C.green),
                _cell('چربی', fmt(n.fat, dec: 1), C.purple),
                _cell('فیبر', fmt(n.fiber, dec: 1), C.greenLight),
              ],
            ),
          ],
        ),
      );

  Widget _cell(String l, String v, Color c) => Column(
        children: [
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 2),
          Text(l, style: TextStyle(fontSize: 11, color: C.muted(context))),
        ],
      );

  void _addCustom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.bg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (c) => const _CustomFoodSheet(),
    );
  }
}

class _CustomFoodSheet extends StatefulWidget {
  const _CustomFoodSheet();
  @override
  State<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<_CustomFoodSheet> {
  final name = TextEditingController();
  final kcal = TextEditingController();
  final p = TextEditingController();
  final c = TextEditingController();
  final f = TextEditingController();
  final fib = TextEditingController();
  final serv = TextEditingController(text: '100');
  final label = TextEditingController(text: 'یک وعده');
  String cat = catDish;

  @override
  void dispose() {
    for (final x in [name, kcal, p, c, f, fib, serv, label]) {
      x.dispose();
    }
    super.dispose();
  }

  Widget _n(String l, TextEditingController ctl) => TextField(
        controller: ctl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: l),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 16, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('افزودن غذای جدید',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('مقدارهای تغذیه‌ای را برای ۱۰۰ گرم وارد کنید (از روی برچسب محصول).',
                style: TextStyle(fontSize: 12, color: C.muted(context))),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'نام غذا')),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final k in foodCategories)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                          label: Text(k),
                          selected: cat == k,
                          onSelected: (_) => setState(() => cat = k)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _n('کالری', kcal)),
              const SizedBox(width: 8),
              Expanded(child: _n('پروتئین', p)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _n('کربوهیدرات', c)),
              const SizedBox(width: 8),
              Expanded(child: _n('چربی', f)),
              const SizedBox(width: 8),
              Expanded(child: _n('فیبر', fib)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: label, decoration: const InputDecoration(labelText: 'اندازه هر وعده'))),
              const SizedBox(width: 8),
              Expanded(child: _n('گرم هر وعده', serv)),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final k = parseNum(kcal.text);
                final sv = parseNum(serv.text);
                if (name.text.trim().isEmpty || k == null || sv == null || sv <= 0) {
                  toast(context, 'نام، کالری و گرم هر وعده را وارد کنید.');
                  return;
                }
                final food = Food(
                  name: name.text.trim(),
                  category: cat,
                  kcal: k,
                  protein: parseNum(p.text) ?? 0,
                  carbs: parseNum(c.text) ?? 0,
                  fat: parseNum(f.text) ?? 0,
                  fiber: parseNum(fib.text) ?? 0,
                  servingG: sv,
                  servingLabel: label.text.trim().isEmpty ? 'یک وعده' : label.text.trim(),
                  custom: true,
                );
                await context.read<AppState>().addCustomFood(food);
                if (context.mounted) {
                  Navigator.pop(context);
                  toast(context, 'غذا به بانک اضافه شد.');
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }
}
