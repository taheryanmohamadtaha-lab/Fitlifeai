import 'package:flutter/material.dart';

import '../core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.darkBg,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: v, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Image.asset('assets/icon/icon.png', width: 130, height: 130),
              ),
              const SizedBox(height: 22),
              const Text('فیت‌لایف',
                  style: TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('کاهش وزن اصولی، با مراقبت از کمر',
                  style: TextStyle(color: Color(0xFF9A9AA3), fontSize: 13)),
              const SizedBox(height: 28),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: C.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
