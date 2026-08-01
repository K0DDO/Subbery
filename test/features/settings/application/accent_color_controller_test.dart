import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subberry/core/theme/app_accent_theme.dart';
import 'package:subberry/features/settings/application/accent_color_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses peach orange as the default accent', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AccentColorController();

    await Future<void>.delayed(Duration.zero);

    expect(controller.state, AppAccentChoice.peach);
    controller.dispose();
  });

  test('restores the saved accent color', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accent_color': AppAccentChoice.emerald.name,
    });
    final controller = AccentColorController();

    await Future<void>.delayed(Duration.zero);

    expect(controller.state, AppAccentChoice.emerald);
    controller.dispose();
  });

  test('persists a new accent color', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AccentColorController();
    await Future<void>.delayed(Duration.zero);

    await controller.setAccent(AppAccentChoice.violet);
    final preferences = await SharedPreferences.getInstance();

    expect(controller.state, AppAccentChoice.violet);
    expect(preferences.getString('accent_color'), AppAccentChoice.violet.name);
    controller.dispose();
  });
}
