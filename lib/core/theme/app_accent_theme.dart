import 'package:flutter/material.dart';

enum AppAccentChoice {
  coral(label: 'Коралловый', seed: Color(0xFFE67F73)),
  emerald(label: 'Мятно-зелёный', seed: Color(0xFF63B887)),
  blue(label: 'Небесно-синий', seed: Color(0xFF6696C8)),
  violet(label: 'Лавандовый', seed: Color(0xFF9878C4)),
  peach(label: 'Персиково-оранжевый', seed: Color(0xFFEC9564)),
  gold(label: 'Тёплая охра', seed: Color(0xFFD7A14F));

  const AppAccentChoice({required this.label, required this.seed});

  final String label;
  final Color seed;

  Color get primary => seed;
  Color get secondary => _shiftLightness(seed, 0.12);
  Color get tertiary => _shiftLightness(seed, -0.14);
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
  });

  factory SubberryTheme.fromChoice(
    AppAccentChoice choice,
    Brightness brightness,
  ) => SubberryTheme.fromSeed(choice.seed, brightness);

  factory SubberryTheme.fromSeed(Color seed, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = seed;
    final primaryLight = _shiftLightness(primary, 0.12);
    final primaryDark = _shiftLightness(primary, -0.14);
    final neutralStart = isDark
        ? const Color(0xFF171519)
        : const Color(0xFFDCC2B8);
    final neutralEnd = isDark
        ? const Color(0xFF211B22)
        : const Color(0xFFE2CBC1);
    final mutedBase = isDark
        ? const Color(0xFFBAAFB0)
        : const Color(0xFF665A58);
    return SubberryTheme(
      primary: primary,
      primaryLight: primaryLight,
      primaryDark: primaryDark,
      glowColor: primary.withValues(alpha: 0.4),
      glassTint: primary.withValues(alpha: isDark ? 0.14 : 0.12),
      softBackgroundTint: Color.lerp(
        neutralStart,
        primary,
        isDark ? 0.1 : 0.16,
      )!,
      borderColor: primary.withValues(alpha: isDark ? 0.34 : 0.34),
      mutedTextColor: Color.lerp(mutedBase, primary, isDark ? 0.08 : 0.06)!,
      success: _semantic(const Color(0xFF6F9F7C), brightness),
      warning: _semantic(const Color(0xFFC3975B), brightness),
      error: _semantic(const Color(0xFFC56F75), brightness),
      info: primaryLight,
      backgroundStart: Color.lerp(
        neutralStart,
        primaryDark,
        isDark ? 0.1 : 0.1,
      )!,
      backgroundEnd: Color.lerp(neutralEnd, primary, isDark ? 0.13 : 0.18)!,
      backgroundAccent: Color.lerp(
        neutralEnd,
        primaryLight,
        isDark ? 0.1 : 0.14,
      )!,
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

  Color get secondary => primaryLight;
  Color get tertiary => primaryDark;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryLight, primary, primaryDark],
  );

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

Color _semantic(Color color, Brightness brightness) {
  return brightness == Brightness.dark
      ? _shiftLightness(color, 0.06)
      : _shiftLightness(color, -0.04);
}
