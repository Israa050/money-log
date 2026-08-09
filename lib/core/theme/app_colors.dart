import 'package:flutter/material.dart';

/// Semantic color tokens for the StockFlow UI, mirrored from the
/// approved design (warm editorial fintech look). Each token has a
/// light and dark value; use [AppColors.of] to read the active set.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ground,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.line,
    required this.lineSoft,
    required this.accent,
    required this.accentInk,
    required this.accentWash,
    required this.income,
    required this.incomeWash,
    required this.expense,
    required this.expenseWash,
  });

  final Color ground;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color line;
  final Color lineSoft;
  final Color accent;
  final Color accentInk;
  final Color accentWash;
  final Color income;
  final Color incomeWash;
  final Color expense;
  final Color expenseWash;

  static const light = AppColors(
    ground: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF10151C),
    inkSoft: Color(0xFF4A5568),
    inkFaint: Color(0xFF8B95A5),
    line: Color(0xFFE4E8EE),
    lineSoft: Color(0xFFEEF1F5),
    accent: Color(0xFF4A6FD4),
    accentInk: Color(0xFFFFFFFF),
    accentWash: Color(0xFFEAEFFC),
    income: Color(0xFF2F7D57),
    incomeWash: Color(0xFFE4F3EA),
    expense: Color(0xFFB84A38),
    expenseWash: Color(0xFFFBEAE7),
  );

  static const dark = AppColors(
    ground: Color(0xFF0B0F14),
    surface: Color(0xFF141B23),
    surfaceRaised: Color(0xFF182029),
    ink: Color(0xFFEDF1F5),
    inkSoft: Color(0xFFA7B1BE),
    inkFaint: Color(0xFF6B7583),
    line: Color(0xFF232C37),
    lineSoft: Color(0xFF1C242E),
    accent: Color(0xFF7B98E8),
    accentInk: Color(0xFF0B0F14),
    accentWash: Color(0xFF1B2436),
    income: Color(0xFF5FBE8B),
    incomeWash: Color(0xFF16261E),
    expense: Color(0xFFE08872),
    expenseWash: Color(0xFF2A1B18),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? ground,
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? line,
    Color? lineSoft,
    Color? accent,
    Color? accentInk,
    Color? accentWash,
    Color? income,
    Color? incomeWash,
    Color? expense,
    Color? expenseWash,
  }) {
    return AppColors(
      ground: ground ?? this.ground,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentWash: accentWash ?? this.accentWash,
      income: income ?? this.income,
      incomeWash: incomeWash ?? this.incomeWash,
      expense: expense ?? this.expense,
      expenseWash: expenseWash ?? this.expenseWash,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      ground: Color.lerp(ground, other.ground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineSoft: Color.lerp(lineSoft, other.lineSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentWash: Color.lerp(accentWash, other.accentWash, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeWash: Color.lerp(incomeWash, other.incomeWash, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseWash: Color.lerp(expenseWash, other.expenseWash, t)!,
    );
  }
}
