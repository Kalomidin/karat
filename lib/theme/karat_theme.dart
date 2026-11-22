import 'package:material_ui/material_ui.dart';

abstract final class KaratColors {
  static const ink = Color(0xFF1C1712);
  static const cream = Color(0xFFF4EFE6);
  static const paper = Color(0xFFFFFBF5);
  static const gold = Color(0xFFA68456);
  static const goldDeep = Color(0xFF6E4E2E);
  static const line = Color(0xFFE4D8C8);
  static const profit = Color(0xFFE4C48A);
  static const loss = Color(0xFF8C3D32);
  static const lossSoft = Color(0xFFF0B2A8);
}

const TextStyle karatSerif = TextStyle(
  fontFamily: 'Georgia',
  fontFamilyFallback: ['Times New Roman', 'serif'],
);

ThemeData karatTheme() {
  const ink = KaratColors.ink;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8C6840),
    primary: KaratColors.goldDeep,
    onPrimary: KaratColors.cream,
    secondary: KaratColors.gold,
    onSecondary: ink,
    surface: KaratColors.paper,
    onSurface: ink,
    error: KaratColors.loss,
  );
  final base = Typography.material2021().black.apply(
    bodyColor: ink,
    displayColor: ink,
  );
  TextStyle? serif(TextStyle? style) => style?.merge(karatSerif);
  final text = base.copyWith(
    displayLarge: serif(base.displayLarge),
    displayMedium: serif(base.displayMedium),
    displaySmall: serif(base.displaySmall),
    headlineLarge: serif(base.headlineLarge),
    headlineMedium: serif(base.headlineMedium),
    headlineSmall: serif(base.headlineSmall),
    titleLarge: serif(base.titleLarge),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: KaratColors.line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: KaratColors.cream,
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: KaratColors.cream,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KaratColors.paper,
      indicatorColor: KaratColors.gold.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KaratColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KaratColors.goldDeep, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: KaratColors.cream,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: KaratColors.goldDeep),
    ),
  );
}
