import 'package:flutter/material.dart';
import 'dart:ui';

class AppColors {
  // Dark Mode Colors
  static const Color background = Color(0xFF0B0E14);
  static const Color sidebarBackground = Color(0xFF12141C);
  static const Color cardBackground = Color(0xFF141417);
  static const Color cardElevated = Color(0xFF1E212B);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightSidebarBackground = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF9FAFB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);

  // Common Accent Colors
  static const Color accentBlue = Color(0xFF2D62FF);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color iconGrey = Color(0xFF8E9297);
  static const Color pinnedNotePurple = Color(0xFFE0B0FF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF43F5E);
}

extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get themeBackground => isDarkMode ? AppColors.background : AppColors.lightBackground;
  Color get themeSidebarBackground => isDarkMode ? AppColors.sidebarBackground : AppColors.lightSidebarBackground;
  Color get themeCardBackground => isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
  Color get themeCardElevated => isDarkMode ? AppColors.cardElevated : AppColors.lightCardElevated;
  Color get themeTextPrimary => isDarkMode ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get themeTextSecondary => isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class AppTheme {
  static BoxDecoration premiumDecoration({BuildContext? context, double radius = 16, bool isElevated = false}) {
    final bool isDark = context != null ? Theme.of(context).brightness == Brightness.dark : true;
    
    final Color bgColor = isElevated 
        ? (isDark ? AppColors.cardElevated : AppColors.lightCardElevated) 
        : (isDark ? AppColors.cardBackground : AppColors.lightCardBackground);
        
    final Color borderColor = isDark ? Colors.white : Colors.black;
    final Color shadowColor = isDark ? Colors.black : Colors.black26;

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor.withValues(alpha: isElevated ? 0.08 : 0.04), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: isElevated ? 0.2 : (isDark ? 0.1 : 0.03)), 
          blurRadius: isElevated ? 12 : 8, 
          offset: Offset(0, isElevated ? 6 : 4)
        ),
      ],
    );
  }

  static Widget glassBox({required BuildContext context, required Widget child, double radius = 24}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark ? Colors.white : Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: glassColor.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ),
    );
  }
}

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    backgroundColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardBackground,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textSecondary),
  ),
);

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    backgroundColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: AppColors.lightCardBackground,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
    bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
  ),
);
