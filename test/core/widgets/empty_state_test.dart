import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/core/widgets/empty_state.dart';

void main() {
  testWidgets('uses a transparent-theme wordmark in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: const Scaffold(
          body: EmptyState(title: 'Пусто', description: 'Описание'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/icons/subberry_wordmark_light.png',
    );
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('uses a transparent-theme wordmark in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: EmptyState(title: 'Пусто', description: 'Описание'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/icons/subberry_wordmark_dark.png',
    );
    expect(image.fit, BoxFit.contain);
  });
}
