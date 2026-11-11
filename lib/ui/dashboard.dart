import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/calc.dart';
import '../core/fa.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'food_sheets.dart';
import 'pain_screen.dart';
import 'progress.dart';
import 'widgets.dart';

class Dashboard extends StatelessWidget {
  final void Function(int) onGo;
  const Dashboard({super.key, required this.onGo});

  String _coachMessage(AppState s) {
    final p = s.profile!;
    final t = s.todayTotals;
    final hour = DateTime.now().hour;
    if (s.todayLogs.isEmpty) {
      return hour < 11
          ? 'صبح بخیر! با ثبت صبحانه روزت رو شروع کن. هر ثبت کوچک، یک قدم به هدفه.'
          : 'هنوز چیزی برای امروز ثبت نشده. اگه چیزی خوردی، همین حالا ثبتش کن تا دقیق‌تر پیش بریم.';
    }
    if (t.kcal > p.kcal * 1.1) {
      return 'امروز کمی بیشتر از هدف کالری خوردی؛ اشکالی نداره. وعده بعدی رو سبک‌تر انتخاب کن و فردا ادامه بده.';
    }
    if (t.kcal >= p.kcal * 0.9) {
      return 'عالی! به هدف کالری امروز نزدیکی. روند پایدار مهم‌تر از یک روز کامل بودنه.';
    }
    if (t.protein < p.protein * 0.5 && hour >= 15) {
      return 'پروتئین امروزت هنوز کمه؛ مرغ، ماهی، تخم‌مرغ، ماست یا حبوبات می‌تونه کمک کنه.';
    }
    if (s.todayWater < p.waterMl * 0.4 && hour >= 14) {
      return 'یادت نره آب بخوری؛ هنوز کمتر از نصف هدف آب امروز رو نوشیدی.';
    }
    return 'خوب پیش می‌ری! به وعده‌های بعدی با حوصله فکر کن و برنامه رو ادامه بده.';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final t = s.todayTotals;
    final remaining = p.kcal - t.kcal;
    final today = DateTime.now();
    final cur = s.currentWeight;
    final toGoal = cur - p.goalWeight;
    final totalToLose = p.startWeight - p.goalWeight;
    final progress = totalToLose <= 0 ? 1.0 : (s.lostSoFar / totalToLose);
    final bmi = Calc.bmi(cur, p.heightCm);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name.isEmpty ? 'سلام 👋' : 'سلام ${p.name} 👋',
                      style: TextStyle(fontSize: 13, color: C.muted(context))),
                  const SizedBox(height: 2),
                  Text(jalaliLong(today),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/icon/icon.png', width: 44, height: 44),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // کالری
        AppCard(
          padding: const EdgeInsets.all(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB347), Color(0xFFFF8A00)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          child: Row(
            children: [
              Ring(
                value: p.kcal == 0 ? 0 : t.kcal / p.kcal,
                size: 118,
                stroke: 12,
                color: Colors.white,
                track: Colors.black.withOpacity(0.18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fmt(remaining.abs()),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(remaining >= 0 ? 'باقی‌مانده' : 'بیشتر از هدف',
                        style: const TextStyle(fontSize: 10.5, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('کالری امروز',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    _row('مجاز', fmt(p.kcal)),
                    _row('مصرف‌شده', fmt(t.kcal)),
                    _row('باقی‌مانده', fmt(remaining)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // درشت‌مغذی‌ها
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: MacroBar(
                      label: 'پروتئین',
                      valueText: '${fmt(t.protein)} / ${fmt(p.protein)} g',
                      ratio: t.protein / p.protein,
                      color: C.blue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: MacroBar(
                      label: 'کربوهیدرات',
                      valueText: '${fmt(t.carbs)} / ${fmt(p.carbs)} g',
                      ratio: t.carbs / p.carbs,
                      color: C.green,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: MacroBar(
                      label: 'چربی',
                      valueText: '${fmt(t.fat)} / ${fmt(p.fat)} g',
                      ratio: t.fat / p.fat,
                      color: C.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              MacroBar(
                label: 'فیبر',
                valueText: '${fmt(t.fiber)} / ${fmt(p.fiber)} g',
                ratio: t.fiber / p.fiber,
                color: C.greenLight,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // آب
        AppCard(
          child: Row(
            children: [
              Ring(
                value: s.todayWater / p.waterMl,
                size: 70,
                stroke: 8,
                color: C.blue,
                track: C.card2(context),
                child: const Icon(Icons.water_drop_rounded, color: C.blue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('آب مصرفی',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${fmt(s.todayWater)} از ${fmt(p.waterMl)} میلی‌لیتر',
                        style: TextStyle(fontSize: 12.5, color: C.muted(context))),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: s.todayWater <= 0 ? null : () => s.addWater(-250),
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: C.blue),
                onPressed: () => s.addWater(250),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // وزن
        AppCard(
          onTap: () => onGo(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _stat('وزن فعلی', '${fmt(cur, dec: 1)} kg', C.text(context)),
                  _stat('وزن هدف', '${fmt(p.goalWeight, dec: 1)} kg', C.green),
                  _stat('کاهش تاکنون', '${fmt(s.lostSoFar, dec: 1)} kg', C.orange),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.isNaN ? 0 : progress.clamp(0.0, 1.0),
                  minHeight: 9,
                  color: C.green,
                  backgroundColor: C.card2(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                toGoal > 0
                    ? 'تا هدف ${fmt(toGoal, dec: 1)} کیلوگرم مانده  •  BMI فعلی ${fmt(bmi, dec: 1)}'
                    : '🎉 به وزن هدف رسیدی!',
                style: TextStyle(fontSize: 12.5, color: C.muted(context)),
              ),
              if (s.weights.length >= 2) ...[
                const SizedBox(height: 14),
                SizedBox(height: 130, child: WeightChart(entries: s.weights, goal: p.goalWeight, compact: true)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // وعده‌های امروز
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('وعده‌های امروز',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  TextButton(onPressed: () => onGo(1), child: const Text('مشاهده')),
                ],
              ),
              for (final m in mealKeys) _mealRow(context, s, m),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => addFoodFlow(context, meal: _defaultMeal(), day: DateTime.now()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ثبت سریع غذا'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // پیام روز
        AppCard(
          color: C.green.withOpacity(C.dark(context) ? 0.14 : 0.12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: C.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('پیام روز', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_coachMessage(s), style: const TextStyle(fontSize: 13, height: 1.8)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (p.spine) ...[
          if (s.recentEmergency != null) ...[
            AppCard(
              color: C.red.withOpacity(0.18),
              onTap: () => showEmergencyDialog(context),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: C.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'علامت هشدار اخیر ثبت شده است. در صورت ضعف پا، بی‌حسی ناحیه زینی یا اختلال ادرار/مدفوع فوراً به اورژانس بروید.',
                      style: TextStyle(fontSize: 13, height: 1.8, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _PainCard(),
          const SizedBox(height: 12),
          const _SpineCard(),
        ],
      ],
    );
  }

  String _defaultMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return 'breakfast';
    if (h < 16) return 'lunch';
    if (h < 18) return 'snack';
    return 'dinner';
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
            Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      );

  Widget _stat(String l, String v, Color c) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l, style: const TextStyle(fontSize: 11.5, color: Color(0xFF9A9AA3))),
            const SizedBox(height: 4),
            Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c)),
          ],
        ),
      );

  Widget _mealRow(BuildContext context, AppState s, String m) {
    final items = s.todayLogs.where((e) => e.meal == m).toList();
    final kcal = items.fold<double>(0, (a, b) => a + b.n.kcal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_mealIcon(m), size: 20, color: C.muted(context)),
          const SizedBox(width: 10),
          Expanded(child: Text(mealNames[m]!)),
          Text(items.isEmpty ? '—' : '${fmt(kcal)} kcal',
              style: TextStyle(
                  color: items.isEmpty ? C.muted(context) : C.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }

  IconData _mealIcon(String m) {
    switch (m) {
      case 'breakfast':
        return Icons.free_breakfast_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.apple_outlined;
    }
  }
}

class _SpineCard extends StatelessWidget {
  const _SpineCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: C.red.withOpacity(C.dark(context) ? 0.12 : 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: C.red),
              SizedBox(width: 10),
              Text('ایمنی ستون فقرات', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'این برنامه فقط تغذیه و پیگیری وزن را پوشش می‌دهد و هیچ تمرین درمانی پیشنهاد نمی‌کند. '
            'هر نوع ورزش یا حرکت اصلاحی فقط پس از ارزیابی و تأیید پزشک یا فیزیوتراپیست.',
            style: TextStyle(fontSize: 12.5, height: 1.8),
          ),
          const SizedBox(height: 10),
          Text('در این موارد فوراً به اورژانس مراجعه کنید:',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.red)),
          const SizedBox(height: 6),
          const Text(
            '• ضعف جدید یا رو‌به‌پیشرفت پا\n'
            '• بی‌حسی ناحیه زینی (اطراف مقعد و بین پاها)\n'
            '• اختلال جدید در کنترل ادرار یا مدفوع',
            style: TextStyle(fontSize: 12.5, height: 1.9),
          ),
        ],
      ),
    );
  }
}

class _PainCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final last = s.pains.isEmpty ? null : s.pains.last;
    return AppCard(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PainScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing_outlined, color: C.orange),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('وضعیت درد کمر و پا',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Icon(Icons.chevron_left_rounded, color: C.muted(context)),
            ],
          ),
          const SizedBox(height: 12),
          if (last == null)
            Text('هنوز ثبت نشده؛ برای ثبت وضعیت امروز بزنید.',
                style: TextStyle(fontSize: 12.5, color: C.muted(context)))
          else
            Row(
              children: [
                _v(context, 'کمر', last.back, C.orange),
                _v(context, 'پای راست', last.rleg, C.blue),
                _v(context, 'پای چپ', last.lleg, C.purple),
              ],
            ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'آخرین ثبت: ${jalaliShort(parseKey(last.date))} ${faNum(last.time)}',
                style: TextStyle(fontSize: 11.5, color: C.muted(context)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _v(BuildContext context, String l, int v, Color c) => Expanded(
        child: Column(
          children: [
            Text('${faNum(v)}/۱۰',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
            const SizedBox(height: 2),
            Text(l, style: TextStyle(fontSize: 11.5, color: C.muted(context))),
          ],
        ),
      );
}
