import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'campus_map_providers.dart';
import 'campus_map_state.dart';

typedef CampusMapLoadCommand = Future<void> Function();

final campusMapControllerProvider =
    NotifierProvider.autoDispose<CampusMapController, CampusMapState>(
      CampusMapController.new,
    );

final class CampusMapController extends Notifier<CampusMapState> {
  static const loadFailureMessage = '학교 지도를 불러오지 못했습니다.';
  static const loadTimeoutMessage = '학교 지도 연결 시간이 초과되었습니다.';

  late final Duration _loadTimeout;
  late final CampusMapTimerFactory _timerFactory;
  Timer? _timeoutTimer;
  bool _navigationInFlight = false;
  bool _currentNavigationFailed = false;
  bool _disposed = false;

  @override
  CampusMapState build() {
    _loadTimeout = ref.read(campusMapLoadTimeoutProvider);
    _timerFactory = ref.read(campusMapTimerFactoryProvider);
    ref.onDispose(() {
      _disposed = true;
      _timeoutTimer?.cancel();
    });
    return const CampusMapState.loading();
  }

  Future<void> loadInitial(CampusMapLoadCommand command) {
    return _runCommand(command);
  }

  Future<void> reload(CampusMapLoadCommand command) {
    return _runCommand(command);
  }

  void pageStarted() {
    if (_disposed) {
      return;
    }
    _beginNavigation();
  }

  void progressChanged(int progress) {
    if (_disposed ||
        _currentNavigationFailed ||
        state.status != CampusMapStatus.loading) {
      return;
    }

    final normalizedProgress = progress.clamp(0, 100);
    if (state.progress == normalizedProgress) {
      return;
    }
    state = CampusMapState.loading(progress: normalizedProgress);
  }

  void pageFinished() {
    if (_disposed || _currentNavigationFailed) {
      return;
    }
    _finishNavigation();
    state = const CampusMapState.success();
  }

  void webResourceFailed({
    required String description,
    required bool? isForMainFrame,
  }) {
    if (_disposed) {
      return;
    }

    if (isForMainFrame == false) {
      developer.log(
        '캠퍼스 지도 하위 리소스 로드 실패',
        name: 'kku_ottae.campus_map',
        error: description,
      );
      return;
    }

    developer.log(
      '캠퍼스 지도 주 프레임 로드 실패',
      name: 'kku_ottae.campus_map',
      error: description,
    );
    _failNavigation(loadFailureMessage);
  }

  Future<void> _runCommand(CampusMapLoadCommand command) async {
    if (_disposed || _navigationInFlight) {
      return;
    }

    _beginNavigation();
    try {
      await command();
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      developer.log(
        '캠퍼스 지도 로드 명령 실패',
        name: 'kku_ottae.campus_map',
        error: error,
        stackTrace: stackTrace,
      );
      _failNavigation(loadFailureMessage);
    }
  }

  void _beginNavigation() {
    _navigationInFlight = true;
    _currentNavigationFailed = false;
    state = const CampusMapState.loading();
    _restartTimeout();
  }

  void _restartTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = _timerFactory(_loadTimeout, () {
      if (_disposed || state.status != CampusMapStatus.loading) {
        return;
      }
      developer.log('캠퍼스 지도 로드 시간 초과', name: 'kku_ottae.campus_map');
      _failNavigation(loadTimeoutMessage);
    });
  }

  void _finishNavigation() {
    _navigationInFlight = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _failNavigation(String message) {
    _currentNavigationFailed = true;
    _finishNavigation();
    state = CampusMapState.error(message: message);
  }
}
