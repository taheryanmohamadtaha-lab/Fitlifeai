import 'package:flutter/material.dart';

import '../core/calc.dart';
import '../core/fa.dart';
import '../core/theme.dart';
import '../data/models.dart';
import 'widgets.dart';

/// فرم پروفایل (برای شروع برنامه و ویرایش در تنظیمات)
class ProfileForm extends StatefulWidget {
  final Profile initial;
  final double currentWeight;
  final String submitLabel;
  final bool requireDisclaimer;
  final Future<void> Function(Profile) onSubmit;
  final Future<void> Function(double)? onWeightChanged;

  const ProfileForm({
    super.key,
    required this.initial,
    required this.currentWeight,
    required this.submitLabel,
    required this.onSubmit,
    this.requireDisclaimer = false,
    this.onWeightChanged,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late TextEditingController name, age, height, weight, goal, kcal, protein, carbs, fat, fiber, water;
  late bool male;
  late double activity;
  late bool spine;
  bool agreed = false;
  bool saving = false;
  bool manualTargets = false;

  static final activities = <double, String>{
    1.2: 'کم‌تحرک',
    1.375: 'فعالیت سبک',
    1.55: 'فعالیت متوسط',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    name = TextEditingController(text: p.name);
    age = TextEditingController(text: '${p.age}');
    height = TextEditingController(text: _plain(p.heightCm));
    weight = TextEditingController(text: _plain(widget.currentWeight));
    goal = TextEditingController(text: _plain(p.goalWeight));
    kcal = TextEditingController(text: '${p.kcal}');
    protein = TextEditingController(text: '${p.protein}');
    carbs = TextEditingController(text: '${p.carbs}');
    fat = TextEditingController(text: '${p.fat}');
    fiber = TextEditingController(text: '${p.fiber}');
    water = TextEditingController(text: '${p.waterMl}');
    male = p.male;
    activity = p.activity;
    spine = p.spine;
    agreed = !widget.requireDisclaimer;
    for (final c in [age, height, weight, goal]) {
      c.addListener(() => setState(() {}));
    }
  }

  String _plain(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  void dispose() {
    for (final c in [name, age, height, weight, goal, kcal, protein, carbs, fat, fiber, water]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _w => parseNum(weight.text);
  double? get _h => parseNum(height.text);
  int? get _a => parseNum(age.text)?.round();

  void _recalcTargets() {
    final w = _w, h = _h, a = _a;
    if (w == null || h == null || a == null) return;
    final bmr = Calc.bmr(male: male, kg: w, cm: h, age: a);
    final tdee = Calc.tdee(bmr, activity);
    final k = Calc.suggestKcal(tdee: tdee, male: male);
    final t = Calc.targets(kcal: k, kg: w);
    setState(() {
      kcal.text = '${t.kcal}';
      protein.text = '${t.protein}';
      carbs.text = '${t.carbs}';
      fat.text = '${t.fat}';
      fiber.text = '${t.fiber}';
    });
  }

  Future<void> _submit() async {
    final w = _w, h = _h, a = _a, g = parseNum(goal.text);
    final k = parseNum(kcal.text)?.round();
    if (w == null || h == null || a == null || g == null || k == null) {
      toast(context, 'لطفاً سن، قد، وزن، وزن هدف و کالری را درست وارد کنید.');
      return;
    }
    if (a < 18 || a > 90) {
      toast(context, 'سن باید بین ۱۸ تا ۹۰ سال باشد.');
      return;
    }
    if (h < 120 || h > 230 || w < 35 || w > 300 || g < 35 || g > 300) {
      toast(context, 'قد یا وزن واردشده معقول نیست.');
      return;
    }
    if (k < Calc.minSafeKcal(male)) {
      toast(context,
          'کالری روزانه کمتر از ${faNum(Calc.minSafeKcal(male))} ایمن نیست. برای رژیم‌های کم‌کالری‌تر حتماً با پزشک مشورت کنید.');
      return;
    }
    final p = widget.initial;
    p.name = name.text.trim();
    p.male = male;
    p.age = a;
    p.heightCm = h;
    if (p.startWeight == 0 || widget.requireDisclaimer) p.startWeight = w;
    p.goalWeight = g;
    p.activity = activity;
    p.kcal = k;
    p.protein = parseNum(protein.text)?.round() ?? p.protein;
    p.carbs = parseNum(carbs.text)?.round() ?? p.carbs;
    p.fat = parseNum(fat.text)?.round() ?? p.fat;
    p.fiber = parseNum(fiber.text)?.round() ?? p.fiber;
    p.waterMl = parseNum(water.text)?.round() ?? p.waterMl;
    p.spine = spine;
    setState(() => saving = true);
    await widget.onSubmit(p);
    if (widget.onWeightChanged != null && (w - widget.currentWeight).abs() > 0.001) {
      await widget.onWeightChanged!(w);
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = _w, h = _h, a = _a;
    Widget preview = const SizedBox.shrink();
    if (w != null && h != null && a != null && h > 0) {
      final bmi = Calc.bmi(w, h);
      final bmr = Calc.bmr(male: male, kg: w, cm: h, age: a);
      final tdee = Calc.tdee(bmr, activity);
      final k = parseNum(kcal.text) ?? 0;
      final weekly = Calc.weeklyLossKg(tdee: tdee, kcal: k.round());
      preview = AppCard(
        color: C.card2(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('شاخص توده بدنی (BMI)', '${fmt(bmi, dec: 1)}  •  ${Calc.bmiLabel(bmi)}'),
            _kv('متابولیسم پایه (BMR)', '${fmt(bmr)} کیلوکالری'),
            _kv('انرژی مصرفی روزانه (TDEE)', '${fmt(tdee)} کیلوکالری'),
            _kv('کاهش وزن تخمینی', weekly <= 0 ? 'بدون کسری' : '≈ ${fmt(weekly, dec: 2)} کیلوگرم در هفته'),
            if (weekly > 0.75)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('کسری کالری زیاد است؛ سرعت بیش از ۰٫۷۵ کیلوگرم در هفته توصیه نمی‌شود.',
                    style: TextStyle(color: C.orange, fontSize: 12)),
              ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _label('نام (اختیاری)'),
        TextField(controller: name, decoration: const InputDecoration(hintText: 'مثلاً محمدطاها')),
        _label('جنسیت'),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('مرد')),
            ButtonSegment(value: false, label: Text('زن')),
          ],
          selected: {male},
          onSelectionChanged: (s) => setState(() => male = s.first),
        ),
        Row(
          children: [
            Expanded(child: _num('سن (سال)', age)),
            const SizedBox(width: 10),
            Expanded(child: _num('قد (سانتی‌متر)', height)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _num('وزن فعلی (کیلوگرم)', weight)),
            const SizedBox(width: 10),
            Expanded(child: _num('وزن هدف (کیلوگرم)', goal)),
          ],
        ),
        _label('سطح فعالیت روزانه'),
        Wrap(
          spacing: 8,
          children: [
            for (final e in activities.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: activity == e.key,
                onSelected: (_) => setState(() => activity = e.key),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: spine,
          onChanged: (v) => setState(() => spine = v),
          title: const Text('مشکل دیسک کمر / درد کمر دارم'),
          subtitle: const Text('حالت ایمنی ستون فقرات فعال می‌ماند و برنامه هیچ تمرین درمانی پیشنهاد نمی‌دهد.',
              style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 8),
        preview,
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text('هدف‌های روزانه',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: _recalcTargets,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('محاسبه خودکار'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: _num('کالری (kcal)', kcal)),
            const SizedBox(width: 10),
            Expanded(child: _num('پروتئین (گرم)', protein)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _num('کربوهیدرات (گرم)', carbs)),
            const SizedBox(width: 10),
            Expanded(child: _num('چربی (گرم)', fat)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _num('فیبر (گرم)', fiber)),
            const SizedBox(width: 10),
            Expanded(child: _num('آب (میلی‌لیتر)', water)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'این مقدارها نقطه شروع هستند، نه نسخه پزشکی. هر زمان می‌توانید آن‌ها را تغییر دهید.',
          style: TextStyle(fontSize: 12, color: C.muted(context)),
        ),
        if (widget.requireDisclaimer) ...[
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: agreed,
            onChanged: (v) => setState(() => agreed = v ?? false),
            title: const Text(
              'می‌دانم این برنامه جایگزین پزشک یا فیزیوتراپیست نیست و تشخیص یا درمان ارائه نمی‌دهد. '
              'قبل از هر برنامه ورزشی با پزشک مشورت می‌کنم.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: (agreed && !saving) ? _submit : null,
          child: saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(widget.submitLabel),
        ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Text(t, style: TextStyle(fontSize: 13, color: C.muted(context))),
      );

  Widget _num(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: 13, color: C.muted(context)))),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
