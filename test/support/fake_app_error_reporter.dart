import 'package:kku_ottae/core/observability/app_error_report.dart';
import 'package:kku_ottae/core/observability/app_error_reporter.dart';

final class FakeAppErrorReporter implements AppErrorReporter {
  FakeAppErrorReporter({this.errorToThrow});

  final Object? errorToThrow;
  final List<AppErrorReport> reports = [];

  @override
  Future<void> record(AppErrorReport report) async {
    reports.add(report);
    final error = errorToThrow;
    if (error != null) {
      throw error;
    }
  }
}
