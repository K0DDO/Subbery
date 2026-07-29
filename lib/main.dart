import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/notifications/application/notification_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(notificationGatewayProvider).initialize();
  await container.read(notificationSettingsProvider.notifier).initialize();
  container.read(notificationCoordinatorProvider);

  runApp(
    UncontrolledProviderScope(container: container, child: const SubberryApp()),
  );
}
