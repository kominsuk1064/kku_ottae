import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'app_error_report.dart';
import 'app_error_reporter.dart';

final class AppErrorHandlers {
  AppErrorHandlers._({
    required FlutterExceptionHandler? previousFlutterErrorHandler,
    required bool Function(Object, StackTrace)? previousPlatformErrorHandler,
    required FlutterExceptionHandler flutterErrorHandler,
    required bool Function(Object, StackTrace) platformErrorHandler,
  }) : _previousFlutterErrorHandler = previousFlutterErrorHandler,
       _previousPlatformErrorHandler = previousPlatformErrorHandler,
       _flutterErrorHandler = flutterErrorHandler,
       _platformErrorHandler = platformErrorHandler;

  final FlutterExceptionHandler? _previousFlutterErrorHandler;
  final bool Function(Object, StackTrace)? _previousPlatformErrorHandler;
  final FlutterExceptionHandler _flutterErrorHandler;
  final bool Function(Object, StackTrace) _platformErrorHandler;

  static AppErrorHandlers install(AppErrorReporter reporter) {
    final previousFlutterErrorHandler = FlutterError.onError;
    final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;

    void flutterErrorHandler(FlutterErrorDetails details) {
      unawaited(
        _recordSafely(reporter, AppErrorReport.flutter(details, fatal: true)),
      );
    }

    bool platformErrorHandler(Object error, StackTrace stackTrace) {
      unawaited(
        _recordSafely(
          reporter,
          AppErrorReport(
            error: error,
            stackTrace: stackTrace,
            reason: 'Unhandled asynchronous error',
            fatal: true,
          ),
        ),
      );
      return true;
    }

    FlutterError.onError = flutterErrorHandler;
    PlatformDispatcher.instance.onError = platformErrorHandler;

    return AppErrorHandlers._(
      previousFlutterErrorHandler: previousFlutterErrorHandler,
      previousPlatformErrorHandler: previousPlatformErrorHandler,
      flutterErrorHandler: flutterErrorHandler,
      platformErrorHandler: platformErrorHandler,
    );
  }

  void restore() {
    if (identical(FlutterError.onError, _flutterErrorHandler)) {
      FlutterError.onError = _previousFlutterErrorHandler;
    }
    if (identical(PlatformDispatcher.instance.onError, _platformErrorHandler)) {
      PlatformDispatcher.instance.onError = _previousPlatformErrorHandler;
    }
  }

  static Future<void> _recordSafely(
    AppErrorReporter reporter,
    AppErrorReport report,
  ) async {
    try {
      await reporter.record(report);
    } catch (error, stackTrace) {
      developer.log(
        'Global error reporting failed',
        name: 'kku_ottae.observability',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
