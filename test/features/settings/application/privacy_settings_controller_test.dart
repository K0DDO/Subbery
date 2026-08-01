import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subberry/core/utils/app_formatters.dart';
import 'package:subberry/features/settings/application/privacy_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('formats whole rubles without kopecks by default', () {
    expect(AppFormatters.money(428000), contains('4'));
    expect(AppFormatters.money(428000), contains('280'));
    expect(AppFormatters.money(428000), isNot(contains(',')));
    expect(AppFormatters.money(428050, showKopecks: true), contains(',50'));
    expect(AppFormatters.money(428000, showKopecks: true), contains(',00'));
  });

  test('rounds when kopecks are hidden', () {
    expect(AppFormatters.money(428049), equals(AppFormatters.money(428000)));
    expect(AppFormatters.money(428050), equals(AppFormatters.money(428100)));
  });

  test('private mode enables hide and transparent balance', () async {
    final controller = PrivacySettingsController();
    await Future<void>.delayed(Duration.zero);

    await controller.setPrivateMode(true);
    expect(controller.state.privateMode, isTrue);
    expect(controller.state.effectiveHideNumbers, isTrue);
    expect(controller.state.effectiveTransparentBalance, isTrue);

    await controller.setHideNumbers(false);
    expect(controller.state.privateMode, isFalse);
    expect(controller.state.hideNumbers, isFalse);

    controller.dispose();
  });

  test('persists privacy preferences', () async {
    final first = PrivacySettingsController();
    await Future<void>.delayed(Duration.zero);
    await first.setTransparentBalance(true);
    await first.setTransparencyStrength(0.2);
    await first.setHideNumbers(true);
    await first.setShowKopecks(true);
    first.dispose();

    final second = PrivacySettingsController();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(second.state.transparentBalance, isTrue);
    expect(second.state.transparencyStrength, closeTo(0.2, 0.001));
    expect(second.state.hideNumbers, isTrue);
    expect(second.state.showKopecks, isTrue);
    second.dispose();
  });
}
