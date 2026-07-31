import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subberry/features/settings/application/background_pattern_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores the saved background pattern', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'background_pattern': BackgroundPatternChoice.cupid.name,
    });
    final controller = BackgroundPatternController();

    await Future<void>.delayed(Duration.zero);

    expect(controller.state, BackgroundPatternChoice.cupid);
    controller.dispose();
  });

  test('persists a new background pattern', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = BackgroundPatternController();
    await Future<void>.delayed(Duration.zero);

    await controller.setPattern(BackgroundPatternChoice.strawberry);
    final preferences = await SharedPreferences.getInstance();

    expect(controller.state, BackgroundPatternChoice.strawberry);
    expect(
      preferences.getString('background_pattern'),
      BackgroundPatternChoice.strawberry.name,
    );
    controller.dispose();
  });
}
