import 'package:flutter/material.dart';

enum AppAccentChoice {
  coral(label: 'Коралловый', seed: Color(0xFFFF7665)),
  emerald(label: 'Зелёный', seed: Color(0xFF65D46E)),
  blue(label: 'Синий', seed: Color(0xFF4D8DFF)),
  violet(label: 'Фиолетовый', seed: Color(0xFFA855F7)),
  peach(label: 'Персиково-оранжевый', seed: Color(0xFFFFB894)),
  gold(label: 'Оранжевый', seed: Color(0xFFFF9F43));

  const AppAccentChoice({required this.label, required this.seed});

  final String label;
  final Color seed;

  Color get primary => seed;
  Color get secondary => _shiftLightness(seed, 0.14);
  Color get tertiary => _shiftLightness(seed, -0.2);
}

@immutable
class SubberryTheme extends ThemeExtension<SubberryTheme> {
  const SubberryTheme({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.glowColor,
    required this.glassTint,
    required this.softBackgroundTint,
    required this.borderColor,
    required this.mutedTextColor,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.backgroundAccent,
    required this.categoryColors,
  });

  factory SubberryTheme.fromChoice(
    AppAccentChoice choice,
    Brightness brightness,
  ) => SubberryTheme.fromSeed(choice.seed, brightness);

  factory SubberryTheme.fromSeed(Color seed, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = seed;
    final primaryLight = _shiftLightness(primary, 0.14);
    final primaryDark = _shiftLightness(primary, -0.2);
    final neutralStart = isDark
        ? const Color(0xFF141416)
        : const Color(0xFFF7F3F2);
    final neutralEnd = isDark
        ? const Color(0xFF1D1B1F)
        : const Color(0xFFF9F6F3);
    final mutedBase = isDark
        ? const Color(0xFFBCAFB0)
        : const Color(0xFF796765);
    final categories = <Color>[
      primary,
      primaryLight,
      primaryDark,
      Color.lerp(primary, primaryLight, 0.48)!,
      Color.lerp(primary, primaryDark, 0.36)!,
      _shiftSaturation(primaryLight, -0.18),
      _shiftSaturation(primary, -0.28),
      _shiftLightness(primaryDark, isDark ? 0.08 : 0.14),
    ];
    return SubberryTheme(
      primary: primary,
      primaryLight: primaryLight,
      primaryDark: primaryDark,
      glowColor: primary.withValues(alpha: 0.35),
      glassTint: primary.withValues(alpha: isDark ? 0.13 : 0.09),
      softBackgroundTint: Color.lerp(
        neutralStart,
        primary,
        isDark ? 0.11 : 0.15,
      )!,
      borderColor: primary.withValues(alpha: isDark ? 0.28 : 0.2),
      mutedTextColor: Color.lerp(mutedBase, primary, isDark ? 0.1 : 0.08)!,
      success: _semantic(const Color(0xFF65D46E), brightness),
      warning: _semantic(const Color(0xFFFFB24A), brightness),
      error: _semantic(const Color(0xFFE75D6C), brightness),
      info: primaryLight,
      backgroundStart: Color.lerp(
        neutralStart,
        primaryDark,
        isDark ? 0.09 : 0.06,
      )!,
      backgroundEnd: Color.lerp(neutralEnd, primary, isDark ? 0.12 : 0.16)!,
      backgroundAccent: Color.lerp(
        neutralEnd,
        primaryLight,
        isDark ? 0.09 : 0.2,
      )!,
      categoryColors: categories,
    );
  }

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color glowColor;
  final Color glassTint;
  final Color softBackgroundTint;
  final Color borderColor;
  final Color mutedTextColor;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color backgroundAccent;
  final List<Color> categoryColors;

  Color get secondary => primaryLight;
  Color get tertiary => primaryDark;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryLight, primary, primaryDark],
  );

  Color categoryColor(int index) =>
      categoryColors[index % categoryColors.length];

  @override
  SubberryTheme copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? glowColor,
    Color? glassTint,
    Color? softBackgroundTint,
    Color? borderColor,
    Color? mutedTextColor,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? backgroundStart,
    Color? backgroundEnd,
    Color? backgroundAccent,
    List<Color>? categoryColors,
  }) {
    return SubberryTheme(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      glowColor: glowColor ?? this.glowColor,
      glassTint: glassTint ?? this.glassTint,
      softBackgroundTint: softBackgroundTint ?? this.softBackgroundTint,
      borderColor: borderColor ?? this.borderColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      backgroundStart: backgroundStart ?? this.backgroundStart,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      backgroundAccent: backgroundAccent ?? this.backgroundAccent,
      categoryColors: categoryColors ?? this.categoryColors,
    );
  }

  @override
  SubberryTheme lerp(covariant SubberryTheme? other, double t) {
    if (other == null) return this;
    return SubberryTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      softBackgroundTint: Color.lerp(
        softBackgroundTint,
        other.softBackgroundTint,
        t,
      )!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      mutedTextColor: Color.lerp(mutedTextColor, other.mutedTextColor, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      backgroundStart: Color.lerp(backgroundStart, other.backgroundStart, t)!,
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      backgroundAccent: Color.lerp(
        backgroundAccent,
        other.backgroundAccent,
        t,
      )!,
      categoryColors: <Color>[
        for (var index = 0; index < categoryColors.length; index++)
          Color.lerp(categoryColors[index], other.categoryColors[index], t)!,
      ],
    );
  }
}

extension AppAccentContext on BuildContext {
  SubberryTheme get subberryTheme {
    final theme = Theme.of(this);
    return theme.extension<SubberryTheme>() ??
        SubberryTheme.fromSeed(theme.colorScheme.primary, theme.brightness);
  }

  SubberryTheme get accentTheme => subberryTheme;
}

typedef AppAccentTheme = SubberryTheme;

Color _shiftLightness(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.08, 0.94))
      .toColor();
}

Color _shiftSaturation(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withSaturation((hsl.saturation + amount).clamp(0.18, 1.0))
      .toColor();
}

Color _semantic(Color color, Brightness brightness) {
  return brightness == Brightness.dark
      ? _shiftLightness(color, 0.06)
      : _shiftLightness(color, -0.04);
}
