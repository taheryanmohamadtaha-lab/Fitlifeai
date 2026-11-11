import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../coach/coach_engine.dart';
import '../core/fa.dart';
import '../core/theme.dart';
import '../services/ai_online.dart';
import '../state/app_state.dart';
import 'pain_screen.dart';
import 'widgets.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final List<ChatTurn> turns = [];
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  bool busy = false;
  bool offlineNote = false;

  static const chips = [
    'خلاصه امروز',
    'تحلیل روند من',
    'پروتئین کم دارم، چی بخورم؟',
    'کالری باقی‌مانده',
    'سرعت کاهش وزن من چطوره؟',
  ];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    turns.add(ChatTurn(false, CoachEngine.answer('سلام', s).text));
  }

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String raw) async {
    final q = raw.trim();
    if (q.isEmpty || busy) return;
    final s = context.read<AppState>();
    ctrl.clear();
    setState(() {
      turns.add(ChatTurn(true, q));
      busy = true;
    });
    _toEnd();

    // ۱) همیشه اول بررسی ایمنی (آفلاین)؛ این موارد هرگز به سرویس آنلاین نمی‌روند
    final g = CoachEngine.guard(q);
    String reply;
    if (g != null) {
      reply = g.text;
      if (g.emergency && mounted) {
        showEmergencyDialog(context);
      }
    } else {
      final c = AiOnline.config(s);
      reply = '';
      if (c.on && c.consented) {
        try {
          reply = await AiOnline.ask(s, turns);
          offlineNote = false;
        } catch (e) {
          offlineNote = true;
        }
      }
      if (reply.isEmpty) reply = CoachEngine.answer(q, s).text;
    }
    if (!mounted) return;
    setState(() {
      turns.add(ChatTurn(false, reply));
      busy = false;
    });
    _toEnd();
  }

  Future<void> _checkIn() async {
    final s = context.read<AppState>();
    int h = s.checkIn('h') ?? 3;
    int e = s.checkIn('e') ?? 3;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('چک‌این امروز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('گرسنگی: ${faNum('$h')} از ۵'),
              Slider(
                  value: h.toDouble(), min: 1, max: 5, divisions: 4,
                  onChanged: (v) => set(() => h = v.round())),
              Text('انرژی: ${faNum('$e')} از ۵'),
              Slider(
                  value: e.toDouble(), min: 1, max: 5, divisions: 4,
                  onChanged: (v) => set(() => e = v.round())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ثبت')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await s.saveCheckIn(hunger: h, energy: e);
      if (mounted) toast(context, 'ثبت شد.');
    }
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AiOnline.config(s);
    final online = c.on && c.consented;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مربی هوشمند من'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              tooltip: 'چک‌این گرسنگی و انرژی',
              icon: const Icon(Icons.mood_rounded),
              onPressed: _checkIn),
          IconButton(
              tooltip: 'تنظیمات مربی',
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openSettings),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                Icon(online ? Icons.cloud_outlined : Icons.offline_bolt_outlined,
                    size: 16, color: online ? C.blue : C.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    online
                        ? (offlineNote
                            ? 'مربی آنلاین در دسترس نبود؛ پاسخ آفلاین داده شد.'
                            : 'حالت آنلاین روشن است')
                        : 'حالت آفلاین؛ داده‌ها از گوشی خارج نمی‌شود',
                    style: TextStyle(fontSize: 12, color: C.muted(context)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: turns.length + (busy ? 1 : 0),
              itemBuilder: (c, i) {
                if (i == turns.length) {
                  return const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: C.green)),
                    ),
                  );
                }
                final t = turns[i];
                return Align(
                  alignment: t.user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.86),
                    decoration: BoxDecoration(
                      color: t.user ? C.green.withOpacity(0.22) : C.card2(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SelectableText(t.text,
                        style: const TextStyle(fontSize: 14, height: 1.9)),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final t in chips)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(label: Text(t), onPressed: () => _send(t)),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'سؤال خود را بنویسید…',
                        filled: true,
                        fillColor: C.card2(context),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: C.green),
                    onPressed: busy ? null : () => _send(ctrl.text),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'مربی تشخیص بیماری یا تجویز دارو و تمرین درمانی نمی‌دهد؛ برای این موارد با پزشک یا فیزیوتراپیست مشورت کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: C.muted(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// تنظیمات مربی آنلاین (اختیاری، با رضایت صریح)
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final keyCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final baseCtrl = TextEditingController();
  bool hasKey = false;

  @override
  void initState() {
    super.initState();
    final c = AiOnline.config(context.read<AppState>());
    modelCtrl.text = context.read<AppState>().settings['ai_model'] ?? '';
    baseCtrl.text = context.read<AppState>().settings['ai_base'] ?? '';
    AiOnline.readKey().then((k) {
      if (mounted) setState(() => hasKey = k != null && k.isNotEmpty);
    });
    c.hashCode;
  }

  @override
  void dispose() {
    keyCtrl.dispose();
    modelCtrl.dispose();
    baseCtrl.dispose();
    super.dispose();
  }

  Future<void> _turnOn(AppState s) async {
    final c = AiOnline.config(s);
    final ok = await confirmDialog(
      context,
      'رضایت برای ارسال اطلاعات',
      'با روشن‌کردن مربی آنلاین، این موارد به سرویس هوش مصنوعی انتخابی شما ارسال می‌شود: '
      '${AiOnline.describeSharing(c)}.\n\n'
      'هر زمان بخواهید می‌توانید آن را خاموش کنید. پیام‌های مربوط به علائم اورژانسی و سؤال‌های پزشکی '
      'هرگز ارسال نمی‌شوند. ادامه می‌دهید؟',
      ok: 'موافقم',
    );
    if (!ok) return;
    await s.setSettings({'ai_on': '1', 'ai_consent_date': dateKey(DateTime.now())});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AiOnline.config(s);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات مربی'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            child: Text(
              'مربی آفلاین همیشه فعال است و چیزی از گوشی خارج نمی‌کند. '
              'اگر بخواهید پاسخ‌های آزادتر بگیرید، می‌توانید کلید API سرویس خودتان را وارد و مربی آنلاین را روشن کنید.',
              style: TextStyle(fontSize: 13, height: 1.9, color: C.muted(context)),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: c.on && c.consented,
            activeColor: C.green,
            title: const Text('مربی آنلاین'),
            subtitle: const Text('نیازمند اینترنت و کلید API'),
            onChanged: (v) async {
              if (v) {
                await _turnOn(s);
              } else {
                await s.setSettings({'ai_on': '0'});
              }
            },
          ),
          SwitchListTile(
            value: c.shareProfile,
            activeColor: C.green,
            title: const Text('ارسال مشخصات و تغذیه امروز'),
            subtitle: const Text('سن، قد، وزن، هدف‌ها'),
            onChanged: (v) => s.setSettings({'ai_share_profile': v ? '1' : '0'}),
          ),
          SwitchListTile(
            value: c.sharePain,
            activeColor: C.green,
            title: const Text('ارسال آخرین ثبت درد'),
            subtitle: const Text('پیش‌فرض خاموش'),
            onChanged: (v) => s.setSettings({'ai_share_pain': v ? '1' : '0'}),
          ),
          const SectionTitle('سرویس'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'anthropic', label: Text('Anthropic')),
              ButtonSegment(value: 'openai', label: Text('سازگار با OpenAI')),
            ],
            selected: {c.provider},
            onSelectionChanged: (v) => s.setSettings({'ai_provider': v.first}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: keyCtrl,
            obscureText: true,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: hasKey ? 'کلید API (ذخیره شده؛ برای تغییر وارد کنید)' : 'کلید API',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: modelCtrl,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
                labelText: 'نام مدل (اختیاری)', border: OutlineInputBorder()),
          ),
          if (c.provider == 'openai') ...[
            const SizedBox(height: 10),
            TextField(
              controller: baseCtrl,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                  labelText: 'آدرس پایه (مثلاً https://api.openai.com/v1)',
                  border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () async {
              if (keyCtrl.text.trim().isNotEmpty) {
                await AiOnline.saveKey(keyCtrl.text);
                keyCtrl.clear();
                hasKey = true;
              }
              await s.setSettings({
                'ai_model': modelCtrl.text.trim(),
                'ai_base': baseCtrl.text.trim(),
              });
              if (mounted) {
                setState(() {});
                toast(context, 'ذخیره شد.');
              }
            },
            child: const Text('ذخیره'),
          ),
          if (hasKey)
            TextButton(
              onPressed: () async {
                await AiOnline.saveKey('');
                await s.setSettings({'ai_on': '0'});
                if (mounted) setState(() => hasKey = false);
              },
              child: const Text('حذف کلید', style: TextStyle(color: C.red)),
            ),
          const SizedBox(height: 8),
          Text(
            'کلید فقط در حافظه امن همین گوشی نگه‌داری می‌شود و در فایل پشتیبان قرار نمی‌گیرد.',
            style: TextStyle(fontSize: 12, color: C.muted(context), height: 1.8),
          ),
        ],
      ),
    );
  }
}
