import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/profile/application/user_profile_controller.dart';

void main() {
  test('restores saved user name', () async {
    final controller = UserProfileController(_MemoryProfileGateway('Анна'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.name, 'Анна');
  });

  test('normalizes and saves entered name', () async {
    final gateway = _MemoryProfileGateway();
    final controller = UserProfileController(gateway);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.saveName('  Анна   Мария  '), isTrue);
    expect(gateway.name, 'Анна Мария');
    expect(controller.state.name, 'Анна Мария');
  });
}

class _MemoryProfileGateway implements UserProfileGateway {
  _MemoryProfileGateway([this.name]);

  String? name;

  @override
  Future<String?> readName() async => name;

  @override
  Future<void> writeName(String name) async {
    this.name = name;
  }
}
