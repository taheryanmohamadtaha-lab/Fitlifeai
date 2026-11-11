import 'package:flutter/material.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../services/reminders.dart';
import 'widgets.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Map<String, ReminderPrefs>? prefs;
  bool granted = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ReminderService.loadPrefs();
    bool g = true;
    try {
      g = await ReminderService.permissionGranted();
    } catch (_) {}
    if (mounted) {
      setState(() {
        prefs = p;
        granted = g;
      });
    }
  }

  String _fmtTime(TimeOfDay t) =>
      faNum('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');

  Future<void> _toggle(ReminderDef d, bool on) async {
    setState(() => busy = true);
    try {
      if (on) {
        final ok = await ReminderService.requestPermission();
        if (!ok) {
          if (mounted) {
            toast(context, 'اجازه اعلان داده نشد. از تنظیمات گوشی اجازه اعلان فیت‌لایف را فعال کنید.');
            setState(() => granted = false);
          }
          return;
        }
        granted = true;
      }
      await ReminderService.savePref(d.key, on: on);
      final p = prefs![d.key]!;
      if (on) {
        await ReminderService.scheduleOne(d, p.time);
      } else {
        await ReminderService.cancelOne(d);
      }
      prefs = await ReminderService.loadPrefs();
    } catch (_) {
      if (mounted) toast(context, 'تنظیم یادآوری ممکن نشد.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickTime(ReminderDef d) async {
    final cur = prefs![d.key]!;
    final t = await showTimePicker(
      context: context,
      initialTime: cur.time,
      builder: (c, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (t == null) return;
    await ReminderService.savePref(d.key, time: t);
    if (cur.on) await ReminderService.scheduleOne(d, t);
    prefs = await ReminderService.loadPrefs();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = prefs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('یادآوری‌ها'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator(color: C.green))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                if (!granted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      color: C.orange.withOpacity(0.16),
                      child: const Text(
                        'اجازه نمایش اعلان برای فیت‌لایف فعال نیست. هنگام روشن‌کردن هر یادآوری اجازه را تأیید کنید، یا از تنظیمات گوشی فعالش کنید.',
                        style: TextStyle(fontSize: 13, height: 1.8),
                      ),
                    ),
                  ),
                Text(
                  'هر یادآوری را جداگانه روشن یا خاموش کنید و ساعتش را عوض کنید. اعلان‌ها بدون اینترنت کار می‌کنند.',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
                ),
                const SizedBox(height: 10),
                for (final d in reminderDefs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(d.icon, color: p[d.key]!.on ? C.green : C.muted(context)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                                const SizedBox(height: 2),
                                Text(
                                  d.repeats > 1
                                      ? '${d.subtitle} • از ${_fmtTime(p[d.key]!.time)}'
                                      : '${d.subtitle} • ${_fmtTime(p[d.key]!.time)}',
                                  style: TextStyle(fontSize: 12, color: C.muted(context)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'تغییر ساعت',
                            icon: const Icon(Icons.schedule_rounded),
                            onPressed: busy ? null : () => _pickTime(d),
                          ),
                          Switch(
                            value: p[d.key]!.on,
                            activeColor: C.green,
                            onChanged: busy ? null : (v) => _toggle(d, v),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          await ReminderService.rescheduleAll();
                          if (mounted) {
                            setState(() => busy = false);
                            toast(context, 'یادآوری‌ها دوباره تنظیم شد.');
                          }
                        },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تنظیم دوباره همه یادآوری‌ها'),
                ),
                const SizedBox(height: 10),
                Text(
                  'اگر گوشی شما در حالت صرفه‌جویی شدید باتری است، ممکن است اعلان‌ها با تأخیر برسند؛ در آن صورت فیت‌لایف را از محدودیت باتری مستثنی کنید.',
                  style: TextStyle(fontSize: 12, color: C.muted(context), height: 1.8),
                ),
              ],
            ),
    );
  }
}
