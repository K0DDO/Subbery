import 'package:flutter/material.dart';

abstract final class AppColors {
  static const coral = Color(0xFFFF7665);
  static const burgundy = Color(0xFF852E4E);
  static const pink = Color(0xFFDC586D);
  static const peach = Color(0xFFFFB894);

  static const lightBackground = Color(0xFFF8EDEB);
  static const lightBackgroundWarm = Color(0xFFFED5CD);
  static const lightBackgroundPeach = Color(0xFFFADBC6);
  static const lightText = Color(0xFF291C1C);
  static const lightMutedText = Color(0xFF796765);
  static const darkBackground = Color(0xFF171214);
  static const darkBackgroundWarm = Color(0xFF28171D);
  static const darkText = Color(0xFFFFF8F5);
  static const darkMutedText = Color(0xFFBCAFB0);

  static const entertainment = Color(0xFFFF7665);
  static const music = Color(0xFF8FD694);
  static const work = Color(0xFF8FA8FF);
  static const cloud = Color(0xFF79C7FF);
  static const gaming = Color(0xFFB39DDB);
  static const education = Color(0xFFFFD166);
  static const health = Color(0xFFFF9F9F);
  static const other = Color(0xFFC9B8B5);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[peach, coral, pink],
  );
}
