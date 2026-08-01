import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_accent_theme.dart';
import '../../core/theme/app_spacing.dart';

class MorphingSheetNavigator extends StatefulWidget {
  const MorphingSheetNavigator({required this.home, super.key});

  final Widget home;

  static MorphingSheetNavigatorState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_MorphingSheetNavigatorScope>();
    assert(scope != null, 'MorphingSheetNavigator not found in context');
    return scope!.state;
  }

  static MorphingSheetNavigatorState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_MorphingSheetNavigatorScope>()
        ?.state;
  }

  @override
  State<MorphingSheetNavigator> createState() => MorphingSheetNavigatorState();
}

class MorphingSheetNavigatorState extends State<MorphingSheetNavigator> {
  late final List<_SheetPageEntry> _stack = <_SheetPageEntry>[
    _SheetPageEntry(child: widget.home),
  ];
  bool _pageVisible = true;
  bool _transitioning = false;

  bool get canPop => _stack.length > 1;

  String? get currentTitle => _stack.last.title;

  void push(Widget page, {String? title}) {
    if (_transitioning) return;
    unawaited(
      _transitionTo(
        () => _stack.add(_SheetPageEntry(child: page, title: title)),
      ),
    );
  }

  void pop() {
    if (!canPop || _transitioning) return;
    unawaited(_transitionTo(_stack.removeLast));
  }

  Future<void> _transitionTo(VoidCallback updateStack) async {
    _transitioning = true;
    setState(() => _pageVisible = false);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    setState(updateStack);
    // Keep the new page invisible while it reports its intrinsic height and
    // the shared glass surface animates to that geometry.
    await Future<void>.delayed(const Duration(milliseconds: 340));
    if (!mounted) return;

    setState(() => _pageVisible = true);
    _transitioning = false;
  }

  @override
  void didUpdateWidget(covariant MorphingSheetNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.home != widget.home && _stack.length == 1) {
      _stack[0] = _SheetPageEntry(child: widget.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _MorphingSheetNavigatorScope(
      state: this,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: _pageVisible ? Offset.zero : const Offset(-0.03, 0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          opacity: _pageVisible ? 1 : 0,
          child: KeyedSubtree(
            key: ValueKey<int>(_stack.length),
            child: _stack.last.child,
          ),
        ),
      ),
    );
    final geometry = MorphingSheetGeometryScope.maybeOf(context);
    if (geometry == null) return page;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: width,
          maxWidth: width,
          minHeight: 0,
          maxHeight: geometry.maximumHeight,
          child: _SizeReporter(
            onSizeChanged: (size) => geometry.reportHeight(size.height),
            child: SizedBox(width: width, child: page),
          ),
        );
      },
    );
  }
}

class MorphingSheetGeometryScope extends InheritedWidget {
  const MorphingSheetGeometryScope({
    required this.maximumHeight,
    required this.onHeightChanged,
    required super.child,
    super.key,
  });

  final double maximumHeight;
  final ValueChanged<double> onHeightChanged;

  static MorphingSheetGeometryScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MorphingSheetGeometryScope>();
  }

  void reportHeight(double height) => onHeightChanged(height);

  @override
  bool updateShouldNotify(MorphingSheetGeometryScope oldWidget) {
    return maximumHeight != oldWidget.maximumHeight;
  }
}

class MorphingSheetBackButton extends StatelessWidget {
  const MorphingSheetBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = MorphingSheetNavigator.maybeOf(context);
    if (navigator == null || !navigator.canPop) {
      return const SizedBox.shrink();
    }
    final palette = context.subberryTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const ValueKey<String>('morphing-sheet-back'),
          style: TextButton.styleFrom(
            foregroundColor: palette.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: navigator.pop,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          label: Text(
            navigator.currentTitle ?? 'Назад',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetPageEntry {
  const _SheetPageEntry({required this.child, this.title});

  final Widget child;
  final String? title;
}

class _MorphingSheetNavigatorScope extends InheritedWidget {
  const _MorphingSheetNavigatorScope({
    required this.state,
    required super.child,
  });

  final MorphingSheetNavigatorState state;

  @override
  bool updateShouldNotify(_MorphingSheetNavigatorScope oldWidget) {
    return state != oldWidget.state;
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSizeChanged, required super.child});

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _SizeReporterRenderObject(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _SizeReporterRenderObject renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _SizeReporterRenderObject extends RenderProxyBox {
  _SizeReporterRenderObject(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _reportedSize;

  @override
  void performLayout() {
    super.performLayout();
    if (_reportedSize == size) return;
    _reportedSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached && _reportedSize == size) {
        onSizeChanged(size);
      }
    });
  }
}
