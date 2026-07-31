import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_accent_theme.dart';
import 'package:subberry/core/theme/app_theme.dart';

void main() {
  test('builds a coordinated theme for the selected accent', () {
    final theme = AppTheme.darkFor(AppAccentChoice.emerald);
    final accent = theme.extension<AppAccentTheme>();

    expect(theme.colorScheme.primary, AppAccentChoice.emerald.primary);
    expect(theme.colorScheme.secondary, AppAccentChoice.emerald.secondary);
    expect(theme.colorScheme.tertiary, AppAccentChoice.emerald.tertiary);
    expect(accent?.primary, AppAccentChoice.emerald.primary);
    expect(accent?.backgroundStart, isNot(equals(accent?.backgroundEnd)));
  });
}
