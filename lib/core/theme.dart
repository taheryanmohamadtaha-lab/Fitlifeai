import 'package:flutter/material.dart';

/// رنگ‌های برنامه: محیط مشکی، سبز برای سلامتی (هم‌رنگ آیکون)، نارنجی برای کالری
class C {
  static const green = Color(0xFF2EBE6B);
  static const greenDark = Color(0xFF0E9173);
  static const greenLight = Color(0xFF7ED957);
  static const orange = Color(0xFFFF9F1C);
  static const blue = Color(0xFF4DA3FF);
  static const purple = Color(0xFF9B7BFF);
  static const red = Color(0xFFFF5A5F);

  static const darkBg = Color(0xFF0A0A0B);
  static const darkCard = Color(0xFF17171A);
  static const darkCard2 = Color(0xFF222226);

  static const lightBg = Color(0xFFF3F6F4);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFE8EEEA);

  static bool dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static Color card(BuildContext c) => dark(c) ? darkCard : lightCard;
  static Color card2(BuildContext c) => dark(c) ? darkCard2 : lightCard2;
  static Color bg(BuildContext c) => dark(c) ? darkBg : lightBg;
  static Color text(BuildContext c) => dark(c) ? Colors.white : const Color(0xFF14201A);
  static Color muted(BuildContext c) =>
      dark(c) ? const Color(0xFF9A9AA3) : const Color(0xFF5E6B64);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final bg = dark ? C.darkBg : C.lightBg;
  final scheme = ColorScheme.fromSeed(
    seedColor: C.green,
    brightness: b,
  ).copyWith(
    primary: C.green,
    secondary: C.orange,
    surface: dark ? C.darkCard : C.lightCard,
    error: C.red,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Vazirmatn',
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: dark ? Colors.white : const Color(0xFF14201A),
      ),
      iconTheme: IconThemeData(color: dark ? Colors.white : const Color(0xFF14201A)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF111113) : Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: C.green.withOpacity(0.2),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11,
          color: dark ? Colors.white70 : Colors.black87,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? C.darkCard2 : C.lightCard2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
            fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
