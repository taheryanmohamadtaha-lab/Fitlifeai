import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/backup.dart';
import '../services/reminders.dart';
import '../state/app_state.dart';
import 'widgets.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => busy = true);
    try {
      await f();
    } catch (_) {
      if (mounted) toast(context, 'عملیات انجام نشد. دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('پشتیبان‌گیری'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.backup_outlined, color: C.green),
                    SizedBox(width: 10),
                    Text('ساخت نسخه پشتیبان',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'یک فایل شامل پروفایل، وزن‌ها، ثبت غذا، آب، درد کمر و غذاهای افزوده‌شده ساخته می‌شود. '
                  'آن را در «فایل‌ها»، تلگرام یا ایمیل خودتان ذخیره کنید. عکس‌ها در پشتیبان نیستند.',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy ? null : () => _run(BackupService.createAndShare),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('ساخت و ذخیره پشتیبان'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restore_rounded, color: C.orange),
                    SizedBox(width: 10),
                    Text('بازیابی اطلاعات',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'فایل پشتیبان را انتخاب کنید. اطلاعات فعلی گوشی با اطلاعات فایل جایگزین می‌شود.',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final ok = await confirmDialog(
                            context,
                            'بازیابی اطلاعات',
                            'اطلاعات فعلی با فایل پشتیبان جایگزین می‌شود. ادامه می‌دهید؟',
                            ok: 'انتخاب فایل',
                          );
                          if (!ok) return;
                          await _run(() async {
                            final r = await BackupService.pickAndRestore();
                            if (r == null) return;
                            if (r == false) {
                              if (mounted) toast(context, 'این فایل، پشتیبان معتبر فیت‌لایف نیست.');
                              return;
                            }
                            await s.reloadAll();
                            await ReminderService.rescheduleAll();
                            if (mounted) toast(context, 'اطلاعات بازیابی شد.');
                          });
                        },
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('انتخاب فایل پشتیبان'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_chart_outlined, color: C.blue),
                    SizedBox(width: 10),
                    Text('خروجی Excel (CSV)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'وزن‌ها، ثبت غذا و درد کمر در یک فایل قابل‌باز شدن در Excel.',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _run(BackupService.exportCsv),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('ساخت خروجی'),
                ),
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator(color: C.green)),
            ),
        ],
      ),
    );
  }
}
