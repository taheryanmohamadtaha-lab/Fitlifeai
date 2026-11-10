import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'profile_form.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool showForm = false;

  @override
  Widget build(BuildContext context) {
    if (showForm) {
      final init = Profile();
      return Scaffold(
        appBar: AppBar(
          title: const Text('پروفایل شما'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => setState(() => showForm = false),
          ),
        ),
        body: SafeArea(
          child: ProfileForm(
            initial: init,
            currentWeight: init.startWeight,
            submitLabel: 'شروع برنامه',
            requireDisclaimer: true,
            onSubmit: (p) => context.read<AppState>().saveProfile(p, firstTime: true),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: C.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Image.asset('assets/icon/icon.png', width: 120, height: 120),
              ),
              const SizedBox(height: 24),
              const Text('به فیت‌لایف خوش آمدید',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'کاهش وزن اصولی با برنامه غذایی ایرانی، شمارش کالری و پیگیری وزن — '
                'همه بدون اینترنت و فقط روی گوشی خودتان.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB5B5BD), fontSize: 14, height: 1.8),
              ),
              const SizedBox(height: 22),
              _point(Icons.restaurant_menu_rounded, 'بانک غذایی ایرانی و برنامه روزانه و هفتگی'),
              _point(Icons.monitor_weight_outlined, 'پیگیری وزن، دور شکم و مراحل هدف'),
              _point(Icons.shield_outlined, 'طراحی با در نظر گرفتن ایمنی ستون فقرات'),
              const Spacer(),
              FilledButton(
                onPressed: () => setState(() => showForm = true),
                child: const Text('بریم شروع کنیم'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _point(IconData i, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: C.green.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(i, color: C.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
            ),
          ],
        ),
      );
}
