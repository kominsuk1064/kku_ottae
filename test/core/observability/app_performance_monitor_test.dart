import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/core/observability/app_performance_monitor.dart';

import '../../support/fake_app_performance_monitor.dart';

void main() {
  group('GuardedAppPerformanceMonitor', () {
    test('trace 시작 실패를 no-op trace로 격리한다', () async {
      final monitor = GuardedAppPerformanceMonitor(
        FakeAppPerformanceMonitor(startError: StateError('start failed')),
      );

      final trace = await monitor.startTrace('test_trace');

      expect(() => trace.putAttribute('outcome', 'success'), returnsNormally);
      expect(() => trace.setMetric('item_count', 1), returnsNormally);
      await expectLater(trace.stop(), completes);
    });

    test('trace 기록과 종료 실패를 원래 작업에서 격리한다', () async {
      final delegate = FakeAppPerformanceMonitor(
        traceMutationError: StateError('write failed'),
        traceStopError: StateError('stop failed'),
      );
      final monitor = GuardedAppPerformanceMonitor(delegate);

      final trace = await monitor.startTrace('test_trace');

      expect(() => trace.putAttribute('outcome', 'success'), returnsNormally);
      expect(() => trace.setMetric('item_count', 1), returnsNormally);
      await expectLater(trace.stop(), completes);
      expect(delegate.traces.single.stopped, isTrue);
    });

    test('정상 trace 호출을 delegate에 전달한다', () async {
      final delegate = FakeAppPerformanceMonitor();
      final monitor = GuardedAppPerformanceMonitor(delegate);

      final trace = await monitor.startTrace('test_trace');
      trace.putAttribute('outcome', 'success');
      trace.setMetric('item_count', 2);
      await trace.stop();

      final recorded = delegate.traces.single;
      expect(recorded.name, 'test_trace');
      expect(recorded.attributes, {'outcome': 'success'});
      expect(recorded.metrics, {'item_count': 2});
      expect(recorded.stopped, isTrue);
    });
  });
}
