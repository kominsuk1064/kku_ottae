import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/core/observability/app_error_handlers.dart';

import '../../support/fake_app_error_reporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppErrorHandlers', () {
    test('Flutter framework 오류를 fatal report로 전달한다', () async {
      final reporter = FakeAppErrorReporter();
      final handlers = AppErrorHandlers.install(reporter);
      addTearDown(handlers.restore);
      final stackTrace = StackTrace.current;
      final details = FlutterErrorDetails(
        exception: StateError('framework failure'),
        stack: stackTrace,
        context: ErrorDescription('while building the test widget'),
      );

      FlutterError.onError!(details);
      await Future<void>.delayed(Duration.zero);

      expect(reporter.reports, hasLength(1));
      final report = reporter.reports.single;
      expect(report.error, same(details.exception));
      expect(report.stackTrace, same(stackTrace));
      expect(report.fatal, isTrue);
      expect(report.flutterErrorDetails, same(details));
    });

    test('비동기 오류를 처리하고 fatal report로 전달한다', () async {
      final reporter = FakeAppErrorReporter();
      final handlers = AppErrorHandlers.install(reporter);
      addTearDown(handlers.restore);
      final error = StateError('async failure');
      final stackTrace = StackTrace.current;

      final handled = PlatformDispatcher.instance.onError!(error, stackTrace);
      await Future<void>.delayed(Duration.zero);

      expect(handled, isTrue);
      expect(reporter.reports, hasLength(1));
      final report = reporter.reports.single;
      expect(report.error, same(error));
      expect(report.stackTrace, same(stackTrace));
      expect(report.reason, 'Unhandled asynchronous error');
      expect(report.fatal, isTrue);
      expect(report.flutterErrorDetails, isNull);
    });
  });
}
