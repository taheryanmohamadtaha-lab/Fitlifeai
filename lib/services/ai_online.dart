import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/fa.dart';
import '../state/app_state.dart';

class ChatTurn {
  final bool user;
  final String text;
  const ChatTurn(this.user, this.text);
}

class AiConfig {
  final bool on;
  final String provider; // anthropic | openai
  final String model;
  final String baseUrl;
  final bool shareProfile;
  final bool sharePain;
  final bool consented;
  const AiConfig({
    required this.on,
    required this.provider,
    required this.model,
    required this.baseUrl,
    required this.shareProfile,
    required this.sharePain,
    required this.consented,
  });
}

/// مربی آنلاین اختیاری. کلید API در حافظه امن گوشی نگه‌داری می‌شود و در پشتیبان قرار نمی‌گیرد.
class AiOnline {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'fitlife_ai_api_key';

  static Future<String?> readKey() async {
    try {
      return await _storage.read(key: _keyName);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveKey(String key) async {
    if (key.trim().isEmpty) {
      await _storage.delete(key: _keyName);
    } else {
      await _storage.write(key: _keyName, value: key.trim());
    }
  }

  static AiConfig config(AppState s) {
    final m = s.settings;
    final provider = m['ai_provider'] ?? 'anthropic';
    return AiConfig(
      on: m['ai_on'] == '1',
      provider: provider,
      model: (m['ai_model'] ?? '').isNotEmpty
          ? m['ai_model']!
          : (provider == 'anthropic' ? 'claude-sonnet-5-5' : 'gpt-4o-mini'),
      baseUrl: (m['ai_base'] ?? '').isNotEmpty ? m['ai_base']! : 'https://api.openai.com/v1',
      shareProfile: m['ai_share_profile'] == '1',
      sharePain: m['ai_share_pain'] == '1',
      consented: (m['ai_consent_date'] ?? '').isNotEmpty,
    );
  }

  static const _system =
      'تو «مربی هوشمند من» هستی، یک مربی تغذیه و عادت‌های سالم در اپلیکیشن فارسی فیت‌لایف. '
      'همیشه فارسی، کوتاه (حداکثر ۱۵۰ کلمه)، مهربان و عملی پاسخ بده.\n'
      'قوانین سخت:\n'
      '- بیماری تشخیص نده و دارو، دوز یا درمان تجویز نکن.\n'
      '- تمرین درمانی یا اصلاحی پیشنهاد نکن؛ هر ورزش یا حرکت فقط با تأیید پزشک یا فیزیوتراپیست.\n'
      '- کاهش وزن سریع یا رژیم بسیار کم‌کالری را تشویق نکن؛ سرعت مناسب حدود ۰٫۲۵ تا ۰٫۷۵ کیلوگرم در هفته است.\n'
      '- اگر کاربر ضعف جدید پا، بی‌حسی ناحیه زینی یا اختلال ادرار/مدفوع گفت، فقط بگو فوراً به اورژانس مراجعه کند.\n'
      '- هشدارهای عصبی (بی‌حسی، گزگز، انتشار درد) را جدی بگیر و توصیه کن با پزشک صحبت کند.\n'
      '- اگر مطمئن نیستی، بگو و به پزشک یا متخصص تغذیه ارجاع بده.';

  static String _context(AppState s, AiConfig c) {
    if (!c.shareProfile) return 'کاربر اجازه ارسال اطلاعات پروفایل را نداده است.';
    final p = s.profile!;
    final t = s.todayTotals;
    final b = StringBuffer('اطلاعات کاربر (برای شخصی‌سازی):\n');
    b.writeln('- ${p.male ? 'مرد' : 'زن'}، ${p.age} ساله، قد ${p.heightCm.round()} سانتی‌متر');
    b.writeln('- وزن فعلی ${s.currentWeight.toStringAsFixed(1)}، هدف ${p.goalWeight.toStringAsFixed(1)} کیلوگرم');
    b.writeln('- هدف روزانه: ${p.kcal} کیلوکالری، پروتئین ${p.protein}، کربوهیدرات ${p.carbs}، چربی ${p.fat} گرم');
    b.writeln('- امروز: ${t.kcal.round()} کیلوکالری، پروتئین ${t.protein.round()}، کربوهیدرات ${t.carbs.round()}، چربی ${t.fat.round()} گرم');
    if (c.sharePain && s.pains.isNotEmpty) {
      final l = s.pains.last;
      b.writeln('- آخرین ثبت درد: کمر ${l.back}/10، پای راست ${l.rleg}، پای چپ ${l.lleg} (فقط برای رعایت احتیاط)');
    }
    return b.toString();
  }

  /// پاسخ را برمی‌گرداند یا یک Exception با پیام فارسی پرتاب می‌کند
  static Future<String> ask(AppState s, List<ChatTurn> history) async {
    final c = config(s);
    final key = await readKey();
    if (key == null || key.isEmpty) throw Exception('کلید API ثبت نشده است.');

    final turns = history.length > 8 ? history.sublist(history.length - 8) : history;
    final system = '$_system\n\n${_context(s, c)}';

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      late HttpClientRequest req;
      late String body;
      if (c.provider == 'anthropic') {
        req = await client.postUrl(Uri.parse('https://api.anthropic.com/v1/messages'));
        req.headers.set('x-api-key', key);
        req.headers.set('anthropic-version', '2023-06-01');
        body = jsonEncode({
          'model': c.model,
          'max_tokens': 600,
          'system': system,
          'messages': [
            for (final t in turns) {'role': t.user ? 'user' : 'assistant', 'content': t.text}
          ],
        });
      } else {
        var base = c.baseUrl.trim();
        if (base.endsWith('/')) base = base.substring(0, base.length - 1);
        req = await client.postUrl(Uri.parse('$base/chat/completions'));
        req.headers.set('Authorization', 'Bearer $key');
        body = jsonEncode({
          'model': c.model,
          'max_tokens': 600,
          'messages': [
            {'role': 'system', 'content': system},
            for (final t in turns) {'role': t.user ? 'user' : 'assistant', 'content': t.text}
          ],
        });
      }
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(body));
      final res = await req.close().timeout(const Duration(seconds: 45));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw Exception('کلید API پذیرفته نشد.');
      }
      if (res.statusCode == 429) throw Exception('سقف درخواست پر شده؛ کمی بعد تلاش کنید.');
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('خطای سرویس (${res.statusCode}).');
      }
      final j = jsonDecode(text);
      String? out;
      if (c.provider == 'anthropic') {
        final parts = j['content'];
        if (parts is List) {
          out = parts.where((e) => e is Map && e['type'] == 'text').map((e) => e['text']).join('\n');
        }
      } else {
        out = j['choices']?[0]?['message']?['content'] as String?;
      }
      if (out == null || out.trim().isEmpty) throw Exception('پاسخ خالی بود.');
      return out.trim();
    } on SocketException {
      throw Exception('اتصال اینترنت برقرار نیست.');
    } on TimeoutException {
      throw Exception('پاسخی دریافت نشد (زمان تمام شد).');
    } on HandshakeException {
      throw Exception('اتصال امن برقرار نشد.');
    } finally {
      client.close(force: true);
    }
  }

  static String describeSharing(AiConfig c) {
    final l = <String>[
      'متن پیام‌هایی که می‌نویسید',
      if (c.shareProfile) 'سن، جنسیت، قد، وزن، هدف‌ها و خلاصه تغذیه امروز',
      if (c.sharePain) 'آخرین ثبت درد کمر و پا',
    ];
    return l.map(faNum).join('، ');
  }
}
