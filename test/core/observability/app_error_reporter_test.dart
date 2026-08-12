import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/core/observability/app_error_report.dart';
import 'package:kku_ottae/core/observability/app_error_reporter.dart';

import '../../support/fake_app_error_reporter.dart';

void main() {
  group('CompositeAppErrorReporter', () {
    test('모든 reporter에 같은 오류 정보를 전달한다', () async {
      final first = FakeAppErrorReporter();
      final second = FakeAppErrorReporter();
      final reporter = CompositeAppErrorReporter([first, second]);
      final report = AppErrorReport(
        error: StateError('failure'),
        stackTrace: StackTrace.current,
        reason: 'test operation failed',
        fatal: true,
      );

      await reporter.record(report);

      expect(first.reports, [same(report)]);
      expect(second.reports, [same(report)]);
    });

    test('한 reporter의 실패가 다음 reporter를 막지 않는다', () async {
      final failing = FakeAppErrorReporter(
        errorToThrow: StateError('reporter failed'),
      );
      final succeeding = FakeAppErrorReporter();
      final reporter = CompositeAppErrorReporter([failing, succeeding]);
      final report = AppErrorReport(
        error: StateError('original failure'),
        stackTrace: StackTrace.current,
        reason: 'test operation failed',
      );

      await reporter.record(report);

      expect(failing.reports, [same(report)]);
      expect(succeeding.reports, [same(report)]);
    });
  });
}
