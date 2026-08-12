import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/campus_map/application/campus_map_controller.dart';
import 'package:kku_ottae/features/campus_map/application/campus_map_providers.dart';
import 'package:kku_ottae/features/campus_map/application/campus_map_state.dart';

void main() {
  group('CampusMapController', () {
    test('페이지 진행률을 반영하고 완료되면 success 상태가 된다', () async {
      final harness = _createHarness();
      addTearDown(harness.dispose);
      var loadCount = 0;

      await harness.controller.loadInitial(() async => loadCount++);

      expect(loadCount, 1);
      expect(harness.state, const CampusMapState.loading());
      expect(harness.timers.single.duration, const Duration(seconds: 20));

      harness.controller.pageStarted();
      harness.controller.progressChanged(42);
      expect(harness.state, const CampusMapState.loading(progress: 42));

      harness.controller.pageFinished();
      expect(harness.state, const CampusMapState.success());
      expect(harness.timers.last.isActive, isFalse);
    });

    test('주 프레임 오류는 사용자용 error 상태로 바꾸고 늦은 완료를 무시한다', () async {
      final harness = _createHarness();
      addTearDown(harness.dispose);

      await harness.controller.loadInitial(() async {});
      harness.controller.webResourceFailed(
        description: 'net::ERR_NAME_NOT_RESOLVED',
        isForMainFrame: true,
      );

      expect(
        harness.state,
        const CampusMapState.error(
          message: CampusMapController.loadFailureMessage,
        ),
      );
      expect(
        harness.state.errorMessage,
        isNot(contains('ERR_NAME_NOT_RESOLVED')),
      );

      harness.controller.pageFinished();
      expect(harness.state.status, CampusMapStatus.error);
    });

    test('하위 리소스 오류는 전체 지도 오류로 처리하지 않는다', () async {
      final harness = _createHarness();
      addTearDown(harness.dispose);

      await harness.controller.loadInitial(() async {});
      harness.controller.webResourceFailed(
        description: 'image load failed',
        isForMainFrame: false,
      );

      expect(harness.state.status, CampusMapStatus.loading);

      harness.controller.pageFinished();
      expect(harness.state, const CampusMapState.success());
    });

    test('WebView 로드 명령 예외를 사용자용 error 상태로 변환한다', () async {
      final harness = _createHarness();
      addTearDown(harness.dispose);

      await harness.controller.loadInitial(
        () async => throw StateError('platform channel failure'),
      );

      expect(
        harness.state,
        const CampusMapState.error(
          message: CampusMapController.loadFailureMessage,
        ),
      );
      expect(harness.timers.single.isActive, isFalse);
    });

    test('로드 제한 시간이 지나면 timeout을 표시하고 다시 시도할 수 있다', () async {
      final harness = _createHarness();
      addTearDown(harness.dispose);
      var commandCount = 0;

      await harness.controller.loadInitial(() async => commandCount++);
      harness.timers.single.fire();

      expect(
        harness.state,
        const CampusMapState.error(
          message: CampusMapController.loadTimeoutMessage,
        ),
      );

      await harness.controller.reload(() async => commandCount++);
      expect(commandCount, 2);
      expect(harness.state.status, CampusMapStatus.loading);

      harness.controller.pageFinished();
      expect(harness.state.status, CampusMapStatus.success);
    });

    test('진행 중인 로드와 겹치는 새로고침을 건너뛴다', () async {
      final harness = _createHarness();
      addTearDown(harness.dispose);
      final response = Completer<void>();
      var commandCount = 0;

      final firstLoad = harness.controller.loadInitial(() {
        commandCount++;
        return response.future;
      });
      await Future<void>.delayed(Duration.zero);

      await harness.controller.reload(() async => commandCount++);
      expect(commandCount, 1);

      response.complete();
      await firstLoad;
      harness.controller.pageFinished();
      expect(harness.state.status, CampusMapStatus.success);
    });

    test('provider가 해제되면 로드 타이머를 정리한다', () async {
      final harness = _createHarness();

      await harness.controller.loadInitial(() async {});
      final timer = harness.timers.single;
      expect(timer.isActive, isTrue);

      harness.dispose();

      expect(timer.isActive, isFalse);
    });
  });
}

_ControllerHarness _createHarness() {
  final timers = <_ManualTimer>[];
  final container = ProviderContainer(
    overrides: [
      campusMapTimerFactoryProvider.overrideWithValue((duration, callback) {
        final timer = _ManualTimer(duration, callback);
        timers.add(timer);
        return timer;
      }),
    ],
  );
  final subscription = container.listen(
    campusMapControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  return _ControllerHarness(
    container: container,
    subscription: subscription,
    timers: timers,
  );
}

final class _ControllerHarness {
  const _ControllerHarness({
    required this.container,
    required this.subscription,
    required this.timers,
  });

  final ProviderContainer container;
  final ProviderSubscription<CampusMapState> subscription;
  final List<_ManualTimer> timers;

  CampusMapController get controller {
    return container.read(campusMapControllerProvider.notifier);
  }

  CampusMapState get state => container.read(campusMapControllerProvider);

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

final class _ManualTimer implements Timer {
  _ManualTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;

  bool _isActive = true;
  int _tick = 0;

  void fire() {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    _tick++;
    _callback();
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
