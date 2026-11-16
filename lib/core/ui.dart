import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg = Color(0xFF0E1424);
  static const card = Color(0xFF182038);
  static const line = Color(0xFF2A3558);
  static const track = Color(0xFF232C4A);
  static const done = Color(0xFF2A6F69);
  static const text = Color(0xFFE8ECF8);
  static const muted = Color(0xFF9AA4BF);
  static const accent = Color(0xFF5EEAD4);
  static const amber = Color(0xFFFBBF24);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: AppColors.bg,
    surface: AppColors.bg,
    onSurface: AppColors.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.bg,
      indicatorColor: AppColors.track,
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}
