import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/bus/application/bus_providers.dart';
import 'package:kku_ottae/features/bus/domain/bus_arrival.dart';
import 'package:kku_ottae/features/bus/domain/bus_arrival_repository.dart';
import 'package:kku_ottae/features/bus/domain/bus_route_summary.dart';
import 'package:kku_ottae/features/bus/domain/bus_stop.dart';
import 'package:kku_ottae/screens/bus_category_screen.dart';

void main() {
  group('BusArrivalsScreen', () {
    testWidgets('첫 요청이 진행되는 동안 loading 화면을 표시한다', (tester) async {
      final response = Completer<List<BusArrival>>();
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) => response.future,
      );

      await _pumpScreen(tester, repository: repository);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_refreshButton(tester).onPressed, isNull);

      response.complete(const [testArrival]);
      await tester.pumpAndSettle();
    });

    testWidgets('도착 차량이 없으면 empty 화면과 경유 노선을 표시한다', (tester) async {
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) async => const [],
        fetchRoutes: (_) async => const [testRoute],
      );

      await _pumpScreen(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.text('현재 도착 예정 차량이 없습니다.'), findsOneWidget);
      expect(find.text('지나는 노선'), findsOneWidget);
      expect(find.text(testRoute.routeName), findsOneWidget);
      expect(repository.routeRequestCount, 1);
    });

    testWidgets('success 화면에 도착 정보와 즐겨찾기 상태를 표시한다', (tester) async {
      String? toggledFavorite;
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) async => const [testArrival],
      );

      await _pumpScreen(
        tester,
        repository: repository,
        favorites: const {'busroute:route-1'},
        toggleFavorite: (key) => toggledFavorite = key,
      );
      await tester.pumpAndSettle();

      expect(find.text('약 3분 후 · 100'), findsOneWidget);
      expect(find.text('2정류장 전 · 상행'), findsOneWidget);
      expect(find.text('마지막 갱신: 12:34'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star));
      expect(toggledFavorite, 'busroute:route-1');
    });

    testWidgets('요청 실패 시 error 화면과 다시 시도 버튼을 표시한다', (tester) async {
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) async => throw TimeoutException('timeout'),
      );

      await _pumpScreen(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.text('요청 시간 초과'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(_refreshButton(tester).onPressed, isNotNull);
    });

    testWidgets('다시 시도하면 loading을 거쳐 success 화면으로 복구한다', (tester) async {
      final retryResponse = Completer<List<BusArrival>>();
      var requestCount = 0;
      final repository = _FakeBusArrivalRepository(
        fetchArrivals: (_) {
          requestCount++;
          if (requestCount == 1) {
            throw TimeoutException('timeout');
          }
          return retryResponse.future;
        },
      );

      await _pumpScreen(tester, repository: repository);
      await tester.pumpAndSettle();
      expect(find.text('요청 시간 초과'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(requestCount, 2);

      retryResponse.complete(const [testArrival]);
      await tester.pumpAndSettle();

      expect(find.text('약 3분 후 · 100'), findsOneWidget);
      expect(find.text('요청 시간 초과'), findsNothing);
    });
  });
}

const testStop = BusStop(stopId: 'stop-1', stopName: '건국대 정문');
const testArrival = BusArrival(
  routeId: 'route-1',
  routeName: '100',
  minutes: 3,
  stopsAway: 2,
  direction: '상행',
);
const testRoute = BusRouteSummary(routeId: 'route-1', routeName: '100');
final testNow = DateTime(2026, 8, 11, 12, 34);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required BusArrivalRepository repository,
  Set<String> favorites = const {},
  void Function(String)? toggleFavorite,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        busClockProvider.overrideWithValue(() => testNow),
        busPeriodicTimerFactoryProvider.overrideWithValue(
          (_, __) => _NoopPeriodicTimer(),
        ),
      ],
      child: MaterialApp(
        home: BusArrivalsScreen(
          stop: testStop,
          favorites: favorites,
          toggleFavorite: toggleFavorite ?? (_) {},
          tagoKeyEncoded: 'test-key',
          cityCode: '33020',
          repository: repository,
        ),
      ),
    ),
  );
}

IconButton _refreshButton(WidgetTester tester) {
  return tester.widget<IconButton>(
    find.widgetWithIcon(IconButton, Icons.refresh).first,
  );
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

  int routeRequestCount = 0;

  @override
  Future<List<BusArrival>> fetchArrivals({required String stopId}) {
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
  void dispose() {}

  static Future<List<BusRouteSummary>> _emptyRoutes(String _) async => const [];
}

final class _NoopPeriodicTimer implements Timer {
  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;

  @override
  void cancel() {
    _isActive = false;
  }
}
