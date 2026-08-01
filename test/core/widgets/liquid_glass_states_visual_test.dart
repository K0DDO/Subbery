import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/core/widgets/liquid_glass_material.dart';

void main() {
  testWidgets('shows distinct 0, 50, and 100 percent glass states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 620),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: _StrawberryBackground(
              child: Padding(
                padding: const EdgeInsets.all(44),
                child: Row(
                  children: const <Widget>[
                    Expanded(child: _GlassState(strength: 0, label: '0%')),
                    SizedBox(width: 28),
                    Expanded(child: _GlassState(strength: 0.5, label: '50%')),
                    SizedBox(width: 28),
                    Expanded(child: _GlassState(strength: 1, label: '100%')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byType(_StrawberryBackground),
      matchesGoldenFile('goldens/liquid_glass_states_dark.png'),
    );
  });
}

class _StrawberryBackground extends StatelessWidget {
  const _StrawberryBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF241719), Color(0xFF542B31)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(painter: _BerryPatternPainter()),
          child,
        ],
      ),
    );
  }
}

class _BerryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xA0E67F73)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var row = 0; row < 7; row++) {
      for (var column = 0; column < 14; column++) {
        final origin = Offset(column * 90 + (row.isOdd ? 32 : 0), row * 90);
        final berry = Path()
          ..moveTo(origin.dx + 16, origin.dy + 11)
          ..cubicTo(
            origin.dx + 30,
            origin.dy + 5,
            origin.dx + 34,
            origin.dy + 23,
            origin.dx + 16,
            origin.dy + 36,
          )
          ..cubicTo(
            origin.dx - 2,
            origin.dy + 23,
            origin.dx + 2,
            origin.dy + 5,
            origin.dx + 16,
            origin.dy + 11,
          );
        canvas.drawPath(berry, paint);
        canvas.drawLine(
          Offset(origin.dx + 8, origin.dy + 9),
          Offset(origin.dx + 15, origin.dy + 15),
          paint,
        );
        canvas.drawLine(
          Offset(origin.dx + 24, origin.dy + 9),
          Offset(origin.dx + 17, origin.dy + 15),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassState extends StatelessWidget {
  const _GlassState({required this.strength, required this.label});

  final double strength;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassConfig(
      strength: strength,
      child: LiquidGlassMaterial(
        radius: 34,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            Text(
              'Subberry glass',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            Text(
              'Клубничный фон остаётся частью материала',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
