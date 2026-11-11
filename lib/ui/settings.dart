import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/calc.dart';
import '../core/fa.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import 'backup_screen.dart';
import 'coach_screen.dart';
import 'exercises_screen.dart';
import 'pain_screen.dart';
import 'photos_screen.dart';
import 'profile_form.dart';
import 'reminders_screen.dart';
import 'reports_screen.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final bmi = Calc.bmi(s.currentWeight, p.heightCm);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text('پروفایل و تنظیمات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.green.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_rounded, color: C.green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name.isEmpty ? 'کاربر فیت‌لایف' : p.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${p.male ? 'مرد' : 'زن'}  •  ${fmt(p.age)} ساله  •  ${fmt(p.heightCm)} cm',
                          style: TextStyle(fontSize: 12.5, color: C.muted(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _kv(context, 'وزن فعلی / هدف',
                  '${fmt(s.currentWeight, dec: 1)} / ${fmt(p.goalWeight, dec: 1)} kg'),
              _kv(context, 'BMI', '${fmt(bmi, dec: 1)}  •  ${Calc.bmiLabel(bmi)}'),
              _kv(context, 'BMR', '${fmt(s.bmr)} کیلوکالری'),
              _kv(context, 'TDEE', '${fmt(s.tdee)} کیلوکالری'),
              const Divider(height: 24),
              _kv(context, 'کالری هدف', '${fmt(p.kcal)} کیلوکالری'),
              _kv(context, 'پروتئین / کربو / چربی',
                  '${fmt(p.protein)} / ${fmt(p.carbs)} / ${fmt(p.fat)} g'),
              _kv(context, 'فیبر', '${fmt(p.fiber)} g'),
              _kv(context, 'آب روزانه', '${fmt(p.waterMl)} ml'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const _EditProfilePage())),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('ویرایش اطلاعات و هدف‌ها'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              _item(context, Icons.smart_toy_outlined, 'مربی هوشمند من', C.green, const CoachScreen()),
              _item(context, Icons.self_improvement_rounded, 'تمرینات ایمن', C.blue, const ExercisesScreen()),
              _item(context, Icons.healing_outlined, 'پایش درد کمر و پا', C.red, const PainScreen()),
              _item(context, Icons.insights_rounded, 'گزارش‌ها', C.blue, const ReportsScreen()),
              _item(context, Icons.notifications_active_outlined, 'یادآوری‌ها', C.orange, const RemindersScreen()),
              _item(context, Icons.photo_camera_back_outlined, 'عکس‌های پیشرفت', C.purple, const PhotosScreen()),
              _item(context, Icons.backup_outlined, 'پشتیبان‌گیری و بازیابی', C.green, const BackupScreen()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ظاهر برنامه',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                      label: Text('شب')),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                      label: Text('روز')),
                ],
                selected: {s.themeMode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark},
                onSelectionChanged: (v) => s.setTheme(v.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('حریم خصوصی',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                'همه اطلاعات شما فقط روی همین گوشی ذخیره می‌شود و به هیچ سرویسی ارسال نمی‌شود.',
                style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.red,
                  side: const BorderSide(color: C.red),
                  minimumSize: const Size(0, 48),
                ),
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    'حذف کامل اطلاعات',
                    'همه اطلاعات شما (پروفایل، وزن‌ها، ثبت غذا، آب و غذاهای افزوده‌شده) برای همیشه پاک می‌شود. ادامه می‌دهید؟',
                    ok: 'حذف همه',
                    danger: true,
                  );
                  if (ok) await s.wipeAll();
                },
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('حذف کامل اطلاعات'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('فیت‌لایف  •  نسخه ۱٫۰٫۰',
              style: TextStyle(fontSize: 12, color: C.muted(context))),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, IconData i, String t, Color c, Widget page) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: c.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
          child: Icon(i, color: c, size: 22),
        ),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      );

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: 13, color: C.muted(context)))),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _EditProfilePage extends StatelessWidget {
  const _EditProfilePage();

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش اطلاعات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ProfileForm(
          initial: s.profile!,
          currentWeight: s.currentWeight,
          submitLabel: 'ذخیره تغییرات',
          onSubmit: (p) async {
            await s.saveProfile(p);
            if (context.mounted) {
              Navigator.pop(context);
              toast(context, 'تغییرات ذخیره شد.');
            }
          },
          onWeightChanged: (w) => s.saveWeight(DateTime.now(), w, null),
        ),
      ),
    );
  }
}
