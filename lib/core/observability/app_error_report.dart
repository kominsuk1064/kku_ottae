import 'package:flutter/foundation.dart';

final class AppErrorReport {
  const AppErrorReport({
    required this.error,
    required this.stackTrace,
    required this.reason,
    this.fatal = false,
    this.flutterErrorDetails,
  });

  factory AppErrorReport.flutter(
    FlutterErrorDetails details, {
    bool fatal = true,
  }) {
    return AppErrorReport(
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      reason:
          details.context?.toString() ?? 'Unhandled Flutter framework error',
      fatal: fatal,
      flutterErrorDetails: details,
    );
  }

  final Object error;
  final StackTrace stackTrace;
  final String reason;
  final bool fatal;
  final FlutterErrorDetails? flutterErrorDetails;
}
