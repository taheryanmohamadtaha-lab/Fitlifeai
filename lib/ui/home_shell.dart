import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'diet.dart';
import 'food_bank.dart';
import 'progress.dart';
import 'settings.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int index = 0;

  void go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(onGo: go),
      const DietScreen(),
      const FoodBankScreen(),
      const ProgressScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'داشبورد'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'تغذیه'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'بانک غذا'),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), selectedIcon: Icon(Icons.insights_rounded), label: 'پیشرفت'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'من'),
        ],
      ),
    );
  }
}
