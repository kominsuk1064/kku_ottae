import 'dart:developer' as developer;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AppPerformanceMonitor {
  Future<AppPerformanceTrace> startTrace(String name);
}

abstract interface class AppPerformanceTrace {
  void putAttribute(String name, String value);

  void setMetric(String name, int value);

  Future<void> stop();
}

final class NoOpAppPerformanceMonitor implements AppPerformanceMonitor {
  const NoOpAppPerformanceMonitor();

  @override
  Future<AppPerformanceTrace> startTrace(String name) async {
    return const NoOpAppPerformanceTrace();
  }
}

final class NoOpAppPerformanceTrace implements AppPerformanceTrace {
  const NoOpAppPerformanceTrace();

  @override
  void putAttribute(String name, String value) {}

  @override
  void setMetric(String name, int value) {}

  @override
  Future<void> stop() async {}
}

final class FirebaseAppPerformanceMonitor implements AppPerformanceMonitor {
  const FirebaseAppPerformanceMonitor(this._performance);

  final FirebasePerformance _performance;

  @override
  Future<AppPerformanceTrace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return _FirebaseAppPerformanceTrace(trace);
  }
}

final class GuardedAppPerformanceMonitor implements AppPerformanceMonitor {
  const GuardedAppPerformanceMonitor(this._delegate);

  final AppPerformanceMonitor _delegate;

  @override
  Future<AppPerformanceTrace> startTrace(String name) async {
    try {
      final trace = await _delegate.startTrace(name);
      return _GuardedAppPerformanceTrace(trace);
    } catch (error, stackTrace) {
      _logFailure('Performance trace start failed', error, stackTrace);
      return const NoOpAppPerformanceTrace();
    }
  }
}

final class _FirebaseAppPerformanceTrace implements AppPerformanceTrace {
  const _FirebaseAppPerformanceTrace(this._trace);

  final Trace _trace;

  @override
  void putAttribute(String name, String value) {
    _trace.putAttribute(name, value);
  }

  @override
  void setMetric(String name, int value) {
    _trace.setMetric(name, value);
  }

  @override
  Future<void> stop() => _trace.stop();
}

final class _GuardedAppPerformanceTrace implements AppPerformanceTrace {
  const _GuardedAppPerformanceTrace(this._delegate);

  final AppPerformanceTrace _delegate;

  @override
  void putAttribute(String name, String value) {
    try {
      _delegate.putAttribute(name, value);
    } catch (error, stackTrace) {
      _logFailure('Performance trace attribute failed', error, stackTrace);
    }
  }

  @override
  void setMetric(String name, int value) {
    try {
      _delegate.setMetric(name, value);
    } catch (error, stackTrace) {
      _logFailure('Performance trace metric failed', error, stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _delegate.stop();
    } catch (error, stackTrace) {
      _logFailure('Performance trace stop failed', error, stackTrace);
    }
  }
}

void _logFailure(String message, Object error, StackTrace stackTrace) {
  developer.log(
    message,
    name: 'kku_ottae.observability',
    error: error,
    stackTrace: stackTrace,
  );
}

final appPerformanceMonitorProvider = Provider<AppPerformanceMonitor>(
  (_) => const NoOpAppPerformanceMonitor(),
);
