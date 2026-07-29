import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subberry/features/settings/application/app_icon_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('switches and persists selected app icon', () async {
    final gateway = _FakeAppIconGateway();
    final controller = AppIconController(gateway);
    await Future<void>.delayed(Duration.zero);

    expect(
      await controller.selectIcon(AppIconChoice.lightMinimal),
      AppIconSelectionResult.changed,
    );
    expect(gateway.lastIconName, 'light_minimal');
    expect(controller.state.selected, AppIconChoice.lightMinimal);

    final restored = AppIconController(gateway);
    await Future<void>.delayed(Duration.zero);
    expect(restored.state.selected, AppIconChoice.lightMinimal);
  });

  test('keeps current icon when platform update fails', () async {
    final controller = AppIconController(_FakeAppIconGateway(shouldFail: true));
    await Future<void>.delayed(Duration.zero);

    expect(
      await controller.selectIcon(AppIconChoice.darkNeon),
      AppIconSelectionResult.failed,
    );
    expect(controller.state.selected, AppIconChoice.darkGlass);
    expect(controller.state.errorMessage, isNotNull);
  });

  test('does not report a change for the selected icon', () async {
    final gateway = _FakeAppIconGateway();
    final controller = AppIconController(gateway);
    await Future<void>.delayed(Duration.zero);

    expect(
      await controller.selectIcon(AppIconChoice.darkGlass),
      AppIconSelectionResult.unchanged,
    );
    expect(gateway.lastIconName, isNull);
  });
}

class _FakeAppIconGateway implements AppIconGateway {
  _FakeAppIconGateway({this.shouldFail = false});

  final bool shouldFail;
  String? lastIconName;

  @override
  Future<void> setIcon(String? alternateName) async {
    if (shouldFail) throw StateError('icon error');
    lastIconName = alternateName;
  }
}
