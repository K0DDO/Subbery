import 'package:flutter/material.dart';

enum AppAccentChoice {
  coral(
    label: 'Коралловый',
    primary: Color(0xFFFF7665),
    secondary: Color(0xFFFFB894),
    tertiary: Color(0xFFDC586D),
  ),
  emerald(
    label: 'Зелёный',
    primary: Color(0xFF39C985),
    secondary: Color(0xFF8FE3B7),
    tertiary: Color(0xFF20A66B),
  ),
  blue(
    label: 'Синий',
    primary: Color(0xFF4D8DFF),
    secondary: Color(0xFF8EB8FF),
    tertiary: Color(0xFF5367D8),
  ),
  violet(
    label: 'Фиолетовый',
    primary: Color(0xFF9B72F2),
    secondary: Color(0xFFC4A7FF),
    tertiary: Color(0xFF7C52C9),
  ),
  cyan(
    label: 'Бирюзовый',
    primary: Color(0xFF21B8C7),
    secondary: Color(0xFF7DDDE4),
    tertiary: Color(0xFF168B9B),
  ),
  gold(
    label: 'Золотой',
    primary: Color(0xFFE8A72F),
    secondary: Color(0xFFF5CE72),
    tertiary: Color(0xFFC47A18),
  );

  const AppAccentChoice({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final String label;
  final Color primary;
  final Color secondary;
  final Color tertiary;
}

@immutable
class AppAccentTheme extends ThemeExtension<AppAccentTheme> {
  const AppAccentTheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.backgroundAccent,
  });

  factory AppAccentTheme.fromChoice(
    AppAccentChoice choice,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final neutralStart = isDark
        ? const Color(0xFF141416)
        : const Color(0xFFF7F3F2);
    final neutralEnd = isDark
        ? const Color(0xFF1D1B1F)
        : const Color(0xFFF9F6F3);
    return AppAccentTheme(
      primary: choice.primary,
      secondary: choice.secondary,
      tertiary: choice.tertiary,
      backgroundStart: Color.lerp(
        neutralStart,
        choice.tertiary,
        isDark ? 0.08 : 0.08,
      )!,
      backgroundEnd: Color.lerp(
        neutralEnd,
        choice.primary,
        isDark ? 0.12 : 0.16,
      )!,
      backgroundAccent: Color.lerp(
        neutralEnd,
        choice.secondary,
        isDark ? 0.09 : 0.2,
      )!,
    );
  }

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color backgroundAccent;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[secondary, primary, tertiary],
  );

  @override
  AppAccentTheme copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? backgroundStart,
    Color? backgroundEnd,
    Color? backgroundAccent,
  }) {
    return AppAccentTheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      backgroundStart: backgroundStart ?? this.backgroundStart,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      backgroundAccent: backgroundAccent ?? this.backgroundAccent,
    );
  }

  @override
  AppAccentTheme lerp(covariant AppAccentTheme? other, double t) {
    if (other == null) return this;
    return AppAccentTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      backgroundStart: Color.lerp(backgroundStart, other.backgroundStart, t)!,
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      backgroundAccent: Color.lerp(
        backgroundAccent,
        other.backgroundAccent,
        t,
      )!,
    );
  }
}

extension AppAccentContext on BuildContext {
  AppAccentTheme get accentTheme => Theme.of(this).extension<AppAccentTheme>()!;
}
