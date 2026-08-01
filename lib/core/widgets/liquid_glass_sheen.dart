import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shared drifting specular sheen for all liquid-glass surfaces.
///
/// One ticker for the whole app — materials listen; they do not own tickers.
class LiquidGlassSheen extends ChangeNotifier {
  LiquidGlassSheen._();

  static final LiquidGlassSheen instance = LiquidGlassSheen._();

  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  int _listeners = 0;
  bool _enabled = false;

  /// 0..1 looping phase for highlight drift.
  double get phase {
    const periodMs = 7200;
    return (_elapsed.inMilliseconds % periodMs) / periodMs;
  }

  void attach(TickerProvider vsync) {
    if (_ticker != null) return;
    _ticker = vsync.createTicker((elapsed) {
      _elapsed = elapsed;
      if (_enabled && _listeners > 0) {
        notifyListeners();
      }
    });
    _syncTicker();
  }

  void detach() {
    _ticker?.dispose();
    _ticker = null;
  }

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _syncTicker();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _listeners++;
    _syncTicker();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _listeners = (_listeners - 1).clamp(0, 1 << 30);
    _syncTicker();
  }

  void _syncTicker() {
    final ticker = _ticker;
    if (ticker == null) return;
    final shouldRun = _enabled && _listeners > 0;
    if (shouldRun && !ticker.isActive) {
      ticker.start();
    } else if (!shouldRun && ticker.isActive) {
      ticker.stop();
    }
  }
}
