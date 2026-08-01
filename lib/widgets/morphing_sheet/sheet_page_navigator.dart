import 'package:flutter/material.dart';

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

  bool get canPop => _stack.length > 1;

  String? get currentTitle => _stack.last.title;

  void push(Widget page, {String? title}) {
    setState(() {
      _stack.add(_SheetPageEntry(child: page, title: title));
    });
  }

  void pop() {
    if (!canPop) return;
    setState(() {
      _stack.removeLast();
    });
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
    return _MorphingSheetNavigatorScope(
      state: this,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0.06, 0.02),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_stack.length),
          child: _stack.last.child,
        ),
      ),
    );
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
