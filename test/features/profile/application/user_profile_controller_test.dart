import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/profile/application/user_profile_controller.dart';

void main() {
  test('restores saved user name', () async {
    final controller = UserProfileController(_MemoryProfileGateway('Анна'));
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.name, 'Анна');
  });

  test('normalizes and saves entered name', () async {
    final gateway = _MemoryProfileGateway();
    final controller = UserProfileController(gateway);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.saveName('  Анна   Мария  '), isTrue);
    expect(gateway.name, 'Анна Мария');
    expect(controller.state.name, 'Анна Мария');
  });

  test('rejects empty and overly long names', () async {
    final gateway = _MemoryProfileGateway('Анна');
    final controller = UserProfileController(gateway);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.saveName('   '), isFalse);
    expect(await controller.saveName(List.filled(41, 'x').join()), isFalse);
    expect(gateway.name, 'Анна');
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
