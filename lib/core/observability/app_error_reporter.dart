import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_report.dart';

abstract interface class AppErrorReporter {
  Future<void> record(AppErrorReport report);
}

final class DeveloperLogAppErrorReporter implements AppErrorReporter {
  const DeveloperLogAppErrorReporter();

  @override
  Future<void> record(AppErrorReport report) async {
    final flutterErrorDetails = report.flutterErrorDetails;
    if (flutterErrorDetails != null) {
      FlutterError.presentError(flutterErrorDetails);
      return;
    }

    developer.log(
      report.reason,
      name: 'kku_ottae',
      level: report.fatal ? 1200 : 1000,
      error: report.error,
      stackTrace: report.stackTrace,
    );
  }
}

final class FirebaseCrashlyticsAppErrorReporter implements AppErrorReporter {
  const FirebaseCrashlyticsAppErrorReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> record(AppErrorReport report) {
    final flutterErrorDetails = report.flutterErrorDetails;
    if (flutterErrorDetails != null) {
      return _crashlytics.recordError(
        flutterErrorDetails.exceptionAsString(),
        flutterErrorDetails.stack,
        reason: report.reason,
        information:
            flutterErrorDetails.informationCollector?.call() ?? const [],
        printDetails: false,
        fatal: report.fatal,
      );
    }

    return _crashlytics.recordError(
      report.error,
      report.stackTrace,
      reason: report.reason,
      printDetails: false,
      fatal: report.fatal,
    );
  }
}

final class CompositeAppErrorReporter implements AppErrorReporter {
  CompositeAppErrorReporter(Iterable<AppErrorReporter> reporters)
    : _reporters = List<AppErrorReporter>.unmodifiable(reporters);

  final List<AppErrorReporter> _reporters;

  @override
  Future<void> record(AppErrorReport report) async {
    for (final reporter in _reporters) {
      try {
        await reporter.record(report);
      } catch (error, stackTrace) {
        developer.log(
          'Error reporter failed',
          name: 'kku_ottae.observability',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
}

final appErrorReporterProvider = Provider<AppErrorReporter>(
  (_) => const DeveloperLogAppErrorReporter(),
);
