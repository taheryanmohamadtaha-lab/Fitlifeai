import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../data/exercises.dart';
import '../state/app_state.dart';
import 'pain_screen.dart';
import 'widgets.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final gated = p.spine && !s.specialistEvaluated;
    final emergency = s.recentEmergency != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تمرینات تأییدشده'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          AppCard(
            color: C.red.withOpacity(C.dark(context) ? 0.12 : 0.08),
            child: const Text(
              'فیت‌لایف درمان یا تمرین درمانی تجویز نمی‌کند. هر حرکتی فقط وقتی فعال می‌شود که شما ثبت کنید '
              'پزشک یا فیزیوتراپیست همان حرکت را برایتان تأیید کرده است. تعداد و مدت را هم خود متخصص تعیین می‌کند.',
              style: TextStyle(fontSize: 12.5, height: 1.9),
            ),
          ),
          const SizedBox(height: 12),
          if (emergency)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                color: C.red.withOpacity(0.2),
                onTap: () => showEmergencyDialog(context),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: C.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'به‌خاطر علامت هشدار ثبت‌شده در ۳ روز اخیر، همه تمرینات (جز تنفس) غیرفعال است. ابتدا بررسی پزشکی لازم است.',
                        style: TextStyle(fontSize: 13, height: 1.8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _GateCard(),
          for (final g in exGroups) ...[
            SectionTitle(g),
            for (final e in exercises.where((x) => x.group == g)) _tile(context, s, e, gated),
          ],
          const SizedBox(height: 14),
          _History(),
          const SizedBox(height: 14),
          Text(
            'تصویر و ویدئوی آموزشی در این نسخه وجود ندارد؛ از فیزیوتراپیست خود بخواهید حرکت را مستقیم نشانتان دهد.',
            style: TextStyle(fontSize: 12, color: C.muted(context), height: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, AppState s, Exercise e, bool gated) {
    final unlocked = s.exerciseUnlocked(e.id, open: e.open);
    final approved = s.exerciseApproved(e.id);
    String sub;
    if (e.open) {
      sub = 'همیشه در دسترس • ${e.difficulty}';
    } else if (unlocked) {
      sub = 'تأییدشده توسط متخصص • ${e.difficulty}';
    } else if (gated) {
      sub = 'قفل: ابتدا ارزیابی متخصص را ثبت کنید';
    } else if (s.recentEmergency != null) {
      sub = 'قفل: بررسی اورژانسی لازم است';
    } else if (!approved) {
      sub = 'قفل: تأیید متخصص برای این حرکت ثبت نشده';
    } else {
      sub = e.difficulty;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ExerciseDetail(exercise: e))),
        child: Row(
          children: [
            Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                color: unlocked ? C.green : C.muted(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(sub, style: TextStyle(fontSize: 12, color: C.muted(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: C.muted(context)),
          ],
        ),
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    if (!p.spine) {
      return AppCard(
        color: C.card2(context),
        child: Text(
          'در پروفایل، مشکل کمر ثبت نشده است. با این حال هر حرکت را فقط با تأیید متخصص انجام دهید و تأیید هر حرکت را ثبت کنید.',
          style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
        ),
      );
    }
    if (s.specialistEvaluated) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_outlined, color: C.green),
                SizedBox(width: 10),
                Text('ارزیابی متخصص ثبت شده',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${s.evalBy}  •  ${jalaliFull(parseKey(s.evalDate))}',
                style: TextStyle(fontSize: 13, color: C.muted(context))),
            if ((s.settings['spine_eval_note'] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(s.settings['spine_eval_note']!,
                    style: TextStyle(fontSize: 12.5, color: C.muted(context))),
              ),
            const SizedBox(height: 8),
            Text('حالا برای هر حرکت جداگانه، تأیید متخصص را در صفحه همان حرکت ثبت کنید.',
                style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8)),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () async {
                final ok = await confirmDialog(context, 'قفل دوباره',
                    'همه تمرینات دوباره قفل شوند و تأیید حرکت‌ها پاک شود؟',
                    ok: 'قفل کن', danger: true);
                if (!ok) return;
                final m = <String, String>{
                  'spine_eval_date': '',
                  'spine_eval_by': '',
                  'spine_eval_note': '',
                };
                for (final e in exercises) {
                  m['ex_ok_${e.id}'] = '0';
                }
                await s.setSettings(m);
              },
              child: const Text('قفل‌کردن دوباره تمرینات'),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: C.orange),
              SizedBox(width: 10),
              Text('تمرینات درمانی قفل هستند',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'با توجه به درد کمر و درد منتشرشونده به پا، تا وقتی پزشک یا فیزیوتراپیست شما را ارزیابی نکرده، هیچ تمرینی (جز تنفس آرام) فعال نمی‌شود.',
            style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.9),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _evalDialog(context, s),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('ارزیابی متخصص انجام شد'),
          ),
        ],
      ),
    );
  }

  Future<void> _evalDialog(BuildContext context, AppState s) async {
    String by = 'فیزیوتراپیست';
    bool agree = false;
    final note = TextEditingController();
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('ثبت ارزیابی متخصص'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('چه کسی شما را ارزیابی کرد؟'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final o in const ['پزشک', 'فیزیوتراپیست', 'متخصص ستون فقرات'])
                      ChoiceChip(
                        label: Text(o),
                        selected: by == o,
                        onSelected: (_) => set(() => by = o),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'یادداشت (اختیاری)'),
                ),
                const SizedBox(height: 6),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: agree,
                  onChanged: (v) => set(() => agree = v ?? false),
                  title: const Text(
                    'ارزیابی واقعاً انجام شده و فقط حرکت‌هایی را فعال می‌کنم که متخصص تأیید کرده است. '
                    'اگر درد بیشتر شد، تمرین را متوقف می‌کنم.',
                    style: TextStyle(fontSize: 12.5, height: 1.8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')),
            TextButton(
              onPressed: agree
                  ? () async {
                      await s.setSettings({
                        'spine_eval_date': dateKey(dateOnly(DateTime.now())),
                        'spine_eval_by': by,
                        'spine_eval_note': note.text.trim(),
                      });
                      if (c.mounted) Navigator.pop(c);
                    }
                  : null,
              child: const Text('ثبت'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
  }
}

class _History extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.exLogs.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('آخرین جلسه‌ها',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          for (final l in s.exLogs.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${exerciseById(l['ex_id'] as String)?.name ?? l['ex_id']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(jalaliShort(parseKey(l['date'] as String)),
                      style: TextStyle(fontSize: 12, color: C.muted(context))),
                  const SizedBox(width: 10),
                  Text(
                    l['result'] == 'done' ? 'کامل شد' : 'متوقف شد',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: l['result'] == 'done' ? C.green : C.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ExerciseDetail extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetail({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final e = exercise;
    final p = s.profile!;
    final unlocked = s.exerciseUnlocked(e.id, open: e.open);
    final canApprove = !e.open && s.recentEmergency == null && (!p.spine || s.specialistEvaluated);
    final dose = s.exerciseDose(e.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(e.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.summary, style: const TextStyle(fontSize: 14, height: 1.9)),
                const SizedBox(height: 12),
                _kv(context, 'گروه', e.group),
                _kv(context, 'عضلات درگیر', e.muscles),
                _kv(context, 'سطح دشواری', e.difficulty),
                _kv(context, 'نمونه معمول', e.typicalDose),
                if (dose.isNotEmpty) _kv(context, 'دستور متخصص من', dose),
              ],
            ),
          ),
          if (!e.open) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: C.green,
                    value: s.exerciseApproved(e.id),
                    onChanged: canApprove
                        ? (v) => s.setSettings({'ex_ok_${e.id}': v ? '1' : '0'})
                        : null,
                    title: const Text('متخصص من این حرکت را تأیید کرده'),
                    subtitle: Text(
                      canApprove
                          ? 'فقط اگر پزشک یا فیزیوتراپیست همین حرکت را برایتان تأیید کرده روشن کنید.'
                          : (s.recentEmergency != null
                              ? 'به‌خاطر علامت هشدار اخیر، فعال‌سازی ممکن نیست.'
                              : 'ابتدا «ارزیابی متخصص» را در صفحه قبل ثبت کنید.'),
                      style: const TextStyle(fontSize: 12, height: 1.7),
                    ),
                  ),
                  if (s.exerciseApproved(e.id) && canApprove) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => _doseDialog(context, s, e, dose),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('ثبت تعداد/مدت طبق دستور متخصص'),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _list(context, 'روش اجرا', e.steps, Icons.format_list_numbered_rounded, C.green, numbered: true),
          const SizedBox(height: 12),
          _list(context, 'موارد منع', e.contraindications, Icons.block_rounded, C.orange),
          const SizedBox(height: 12),
          _list(context, 'هشدارهای ایمنی', e.warnings, Icons.warning_amber_rounded, C.red),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: unlocked
                ? () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ExerciseSession(exercise: e)))
                : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(unlocked ? 'شروع تمرین' : 'قفل است'),
          ),
        ],
      ),
    );
  }

  Future<void> _doseDialog(BuildContext context, AppState s, Exercise e, String cur) async {
    final c = TextEditingController(text: cur);
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('دستور متخصص'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
              labelText: 'مثلاً: ۸ تکرار، ۲ ست', helperText: 'همان‌طور که متخصص گفته بنویسید'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('انصراف')),
          TextButton(
            onPressed: () async {
              await s.setSettings({'ex_dose_${e.id}': c.text.trim()});
              if (d.mounted) Navigator.pop(d);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    c.dispose();
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 92,
                child: Text(k, style: TextStyle(fontSize: 12.5, color: C.muted(context)))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.6))),
          ],
        ),
      );

  Widget _list(BuildContext context, String title, List<String> items, IconData icon, Color c,
      {bool numbered = false}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${numbered ? '${faNum(i + 1)}. ' : '• '}${items[i]}',
                style: const TextStyle(fontSize: 13.5, height: 1.8),
              ),
            ),
        ],
      ),
    );
  }
}

class ExerciseSession extends StatefulWidget {
  final Exercise exercise;
  const ExerciseSession({super.key, required this.exercise});

  @override
  State<ExerciseSession> createState() => _ExerciseSessionState();
}

class _ExerciseSessionState extends State<ExerciseSession> {
  Timer? timer;
  int sec = 0;
  int step = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => sec++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _clock(int t) => faNum(
      '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}');

  Future<void> _finish(String result) async {
    timer?.cancel();
    final s = context.read<AppState>();
    final e = widget.exercise;
    await s.logExercise(e.id, result, sec);
    if (!mounted) return;
    if (result == 'done') {
      final m = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      m
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تمرین ثبت شد. آفرین!')));
      return;
    }
    final twice = !e.open && s.exerciseStoppedTwice(e.id);
    if (twice) {
      await s.setSettings({'ex_ok_${e.id}': '0'});
    }
    if (!mounted) return;
    final goPain = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.pan_tool_rounded, color: C.orange, size: 38),
        title: const Text('تمرین متوقف شد'),
        content: Text(
          'استراحت کنید و ادامه ندهید. وضعیت کمر و پا را در بخش پایش ثبت کنید.'
          '${twice ? '\n\nاین حرکت دو بار پشت‌سرهم به‌خاطر درد متوقف شد؛ برای ایمنی غیرفعال شد. قبل از ادامه با پزشک یا فیزیوتراپیست صحبت کنید.' : ''}',
          style: const TextStyle(height: 1.8),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('بستن')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('ثبت درد'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (goPain == true) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PainScreen()));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final target = e.timerSec;
    return Scaffold(
      appBar: AppBar(
        title: Text(e.name),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              AppCard(
                child: Column(
                  children: [
                    Text(_clock(sec),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
                    if (target > 0)
                      Text('هدف: ${_clock(target)}',
                          style: TextStyle(fontSize: 12.5, color: C.muted(context))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مرحله ${faNum(step + 1)} از ${faNum(e.steps.length)}',
                          style: TextStyle(fontSize: 12.5, color: C.muted(context))),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(e.steps[step],
                              style: const TextStyle(fontSize: 17, height: 2)),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: step == 0 ? null : () => setState(() => step--),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: step >= e.steps.length - 1
                                ? null
                                : () => setState(() => step++),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _finish('done'),
                icon: const Icon(Icons.check_rounded),
                label: const Text('پایان بدون مشکل'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: C.orange),
                onPressed: () => _finish('pain_stop'),
                icon: const Icon(Icons.pan_tool_rounded),
                label: const Text('درد یا گزگز بیشتر شد — توقف'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.red,
                  side: const BorderSide(color: C.red),
                  minimumSize: const Size(0, 48),
                ),
                onPressed: () async {
                  timer?.cancel();
                  await context.read<AppState>().logExercise(e.id, 'pain_stop', sec);
                  if (!context.mounted) return;
                  await showEmergencyDialog(context);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('ضعف پا / بی‌حسی زینی / اختلال ادرار'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
