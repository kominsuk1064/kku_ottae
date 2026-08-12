import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/core/observability/app_error_reporter.dart';
import 'package:kku_ottae/features/bus/application/bus_arrivals_controller.dart';
import 'package:kku_ottae/features/bus/application/bus_arrivals_state.dart';
import 'package:kku_ottae/features/bus/application/bus_providers.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_exception.dart';
import 'package:kku_ottae/features/bus/domain/bus_arrival.dart';
import 'package:kku_ottae/features/bus/domain/bus_arrival_repository.dart';
import 'package:kku_ottae/features/bus/domain/bus_route_summary.dart';

import '../../../support/fake_app_error_reporter.dart';

void main() {
  group('BusArrivalsController', () {
    test('loading 상태에서 도착 정보 success 상태로 전환한다', () async {
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) async => [testArrival],
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.states.first.status, BusArrivalsStatus.loading);
      final state = harness.readState();
      expect(state.status, BusArrivalsStatus.success);
      expect(state.arrivals, [testArrival]);
      expect(state.lastUpdated, testNow);
      expect(repository.arrivalRequestCount, 1);
      expect(() => state.arrivals.add(testArrival), throwsUnsupportedError);
    });

    test('도착 정보가 없으면 경유 노선을 포함한 empty 상태가 된다', () async {
      const route = BusRouteSummary(routeId: 'route-1', routeName: '100');
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) async => const [],
        fetchRoutes: (_) async => const [route],
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await _settle(harness.container);

      final state = harness.readState();
      expect(state.status, BusArrivalsStatus.empty);
      expect(state.routes, const [route]);
      expect(repository.routeRequestCount, 1);
    });

    test('timeout 오류를 표시하고 재시도로 복구한다', () async {
      final errorReporter = FakeAppErrorReporter();
      var shouldFail = true;
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) async {
          if (shouldFail) {
            shouldFail = false;
            throw TimeoutException('timeout');
          }
          return [testArrival];
        },
      );
      final harness = _createHarness(repository, errorReporter: errorReporter);
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.readState().status, BusArrivalsStatus.error);
      expect(harness.readState().errorMessage, '요청 시간 초과');
      expect(errorReporter.reports, hasLength(1));
      expect(
        errorReporter.reports.single.reason,
        'Bus arrivals refresh failed',
      );
      expect(errorReporter.reports.single.fatal, isFalse);

      await harness.readController().retry();

      expect(harness.readState().status, BusArrivalsStatus.success);
      expect(repository.arrivalRequestCount, 2);
    });

    test('HTTP와 TAGO 응답 오류를 사용자 메시지로 변환한다', () async {
      final errors = <Object, String>{
        const TagoBusHttpException(503): 'HTTP 503',
        const TagoBusResponseException('API XML 오류 응답'): 'API XML 오류 응답',
      };

      for (final entry in errors.entries) {
        final repository = _FakeBusArrivalRepository(
          fetchArrivals: (_) async => throw entry.key,
        );
        final harness = _createHarness(repository);

        await _settle(harness.container);

        expect(harness.readState().status, BusArrivalsStatus.error);
        expect(harness.readState().errorMessage, entry.value);
        harness.dispose();
      }
    });

    test('진행 중인 요청과 겹치는 갱신을 건너뛴다', () async {
      final response = Completer<List<BusArrival>>();
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) => response.future,
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await _settle(harness.container);
      expect(repository.arrivalRequestCount, 1);

      await harness.readController().refresh();
      expect(repository.arrivalRequestCount, 1);

      response.complete([testArrival]);
      await _settle(harness.container);

      expect(harness.readState().status, BusArrivalsStatus.success);
    });

    test('15초마다 갱신하고 provider 해제 시 자원을 정리한다', () async {
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) async => [testArrival],
      );
      final harness = _createHarness(repository);
      addTearDown(harness.container.dispose);

      await _settle(harness.container);
      expect(harness.timer.duration, const Duration(seconds: 15));
      expect(repository.arrivalRequestCount, 1);

      harness.timer.fire();
      await _settle(harness.container);
      expect(repository.arrivalRequestCount, 2);

      harness.subscription.close();
      await _settle(harness.container);

      expect(harness.timer.isActive, isFalse);
      expect(repository.disposed, isTrue);
    });
  });
}

const testArrival = BusArrival(
  routeId: 'route-1',
  routeName: '100',
  minutes: 3,
  stopsAway: 2,
  direction: '상행',
);
final testNow = DateTime(2026, 8, 11, 12, 0);

_ControllerHarness _createHarness(
  _FakeBusArrivalRepository repository, {
  FakeAppErrorReporter? errorReporter,
}) {
  late _ManualPeriodicTimer timer;
  final reporter = errorReporter ?? FakeAppErrorReporter();
  final container = ProviderContainer(
    overrides: [
      appErrorReporterProvider.overrideWithValue(reporter),
      busArrivalRepositoryFactoryProvider.overrideWithValue((_) => repository),
      busClockProvider.overrideWithValue(() => testNow),
      busPeriodicTimerFactoryProvider.overrideWithValue((duration, callback) {
        timer = _ManualPeriodicTimer(duration, callback);
        return timer;
      }),
    ],
  );
  const request = BusArrivalsRequest(
    stopId: 'stop-1',
    serviceKey: 'test-key',
    cityCode: '33020',
  );
  final states = <BusArrivalsState>[];
  final subscription = container.listen(
    busArrivalsControllerProvider(request),
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _ControllerHarness(
    container: container,
    request: request,
    subscription: subscription,
    states: states,
    timer: timer,
  );
}

Future<void> _settle(ProviderContainer container) async {
  for (var index = 0; index < 5; index++) {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
  }
}

final class _ControllerHarness {
  const _ControllerHarness({
    required this.container,
    required this.request,
    required this.subscription,
    required this.states,
    required this.timer,
  });

  final ProviderContainer container;
  final BusArrivalsRequest request;
  final ProviderSubscription<BusArrivalsState> subscription;
  final List<BusArrivalsState> states;
  final _ManualPeriodicTimer timer;

  BusArrivalsState readState() {
    return container.read(busArrivalsControllerProvider(request));
  }

  BusArrivalsController readController() {
    return container.read(busArrivalsControllerProvider(request).notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

final class _FakeBusArrivalRepository implements BusArrivalRepository {
  _FakeBusArrivalRepository({
    required Future<List<BusArrival>> Function(String stopId) fetchArrivals,
    Future<List<BusRouteSummary>> Function(String stopId) fetchRoutes =
        _emptyRoutes,
  }) : _fetchArrivals = fetchArrivals,
       _fetchRoutes = fetchRoutes;

  final Future<List<BusArrival>> Function(String stopId) _fetchArrivals;
  final Future<List<BusRouteSummary>> Function(String stopId) _fetchRoutes;

  int arrivalRequestCount = 0;
  int routeRequestCount = 0;
  bool disposed = false;

  @override
  Future<List<BusArrival>> fetchArrivals({required String stopId}) {
    arrivalRequestCount++;
    return _fetchArrivals(stopId);
  }

  @override
  Future<List<BusRouteSummary>> fetchRoutesThroughStop({
    required String stopId,
  }) {
    routeRequestCount++;
    return _fetchRoutes(stopId);
  }

  @override
  void dispose() {
    disposed = true;
  }

  static Future<List<BusRouteSummary>> _emptyRoutes(String _) async => const [];
}

final class _ManualPeriodicTimer implements Timer {
  _ManualPeriodicTimer(this.duration, this._callback);

  final Duration duration;
  final void Function(Timer timer) _callback;

  bool _isActive = true;
  int _tick = 0;

  void fire() {
    if (!_isActive) {
      return;
    }
    _tick++;
    _callback(this);
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _isActive = false;
  }
}
