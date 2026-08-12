import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/observability/app_error_report.dart';
import '../../../core/observability/app_error_reporter.dart';
import '../data/tago_bus_exception.dart';
import '../domain/bus_arrival_repository.dart';
import '../domain/bus_route_summary.dart';
import 'bus_arrivals_state.dart';
import 'bus_providers.dart';

final busArrivalsControllerProvider = NotifierProvider.autoDispose
    .family<BusArrivalsController, BusArrivalsState, BusArrivalsRequest>(
      BusArrivalsController.new,
    );

final class BusArrivalsRequest {
  const BusArrivalsRequest({
    required this.stopId,
    required this.serviceKey,
    required this.cityCode,
    this.repository,
  });

  final String stopId;
  final String serviceKey;
  final String cityCode;
  final BusArrivalRepository? repository;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BusArrivalsRequest &&
            stopId == other.stopId &&
            serviceKey == other.serviceKey &&
            cityCode == other.cityCode &&
            identical(repository, other.repository);
  }

  @override
  int get hashCode {
    return Object.hash(
      stopId,
      serviceKey,
      cityCode,
      identityHashCode(repository),
    );
  }
}

final class BusArrivalsController extends Notifier<BusArrivalsState> {
  BusArrivalsController(this.request);

  final BusArrivalsRequest request;

  late final BusArrivalRepository _repository;
  late final BusClock _clock;
  late final AppErrorReporter _errorReporter;
  Timer? _poller;
  bool _ownsRepository = false;
  bool _requestInFlight = false;
  bool _disposed = false;

  @override
  BusArrivalsState build() {
    _ownsRepository = request.repository == null;
    _repository =
        request.repository ??
        ref.read(busArrivalRepositoryFactoryProvider)(
          BusRepositoryConfiguration(
            serviceKey: request.serviceKey,
            cityCode: request.cityCode,
          ),
        );
    _clock = ref.read(busClockProvider);
    _errorReporter = ref.read(appErrorReporterProvider);

    ref.onDispose(() {
      _disposed = true;
      _poller?.cancel();
      if (_ownsRepository) {
        _repository.dispose();
      }
    });

    _poller = ref.read(busPeriodicTimerFactoryProvider)(
      ref.read(busPollingIntervalProvider),
      (_) => unawaited(refresh()),
    );
    unawaited(Future<void>.microtask(refresh));

    return BusArrivalsState.loading();
  }

  Future<void> refresh() async {
    if (_disposed || _requestInFlight) {
      return;
    }

    _requestInFlight = true;
    final previousLastUpdated = state.lastUpdated;
    if (state.status == BusArrivalsStatus.success ||
        state.status == BusArrivalsStatus.empty) {
      state = state.startRefreshing();
    } else {
      state = BusArrivalsState.loading(lastUpdated: previousLastUpdated);
    }

    try {
      final arrivals = await _repository.fetchArrivals(stopId: request.stopId);
      if (_disposed) {
        return;
      }

      if (arrivals.isEmpty) {
        final routes = await _fetchRoutesThroughStop();
        if (_disposed) {
          return;
        }
        state = BusArrivalsState.empty(routes: routes, lastUpdated: _clock());
      } else {
        state = BusArrivalsState.success(
          arrivals: arrivals,
          lastUpdated: _clock(),
        );
      }
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      unawaited(
        _errorReporter.record(
          AppErrorReport(
            error: error,
            stackTrace: stackTrace,
            reason: 'Bus arrivals refresh failed',
          ),
        ),
      );
      state = BusArrivalsState.error(
        message: _userMessage(error),
        lastUpdated: previousLastUpdated,
      );
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> retry() => refresh();

  Future<List<BusRouteSummary>> _fetchRoutesThroughStop() async {
    try {
      return await _repository.fetchRoutesThroughStop(stopId: request.stopId);
    } catch (error, stackTrace) {
      unawaited(
        _errorReporter.record(
          AppErrorReport(
            error: error,
            stackTrace: stackTrace,
            reason: 'Bus routes fallback failed',
          ),
        ),
      );
      return const [];
    }
  }

  String _userMessage(Object error) {
    if (error is TimeoutException) {
      return '요청 시간 초과';
    }
    if (error is TagoBusHttpException) {
      return 'HTTP ${error.statusCode}';
    }
    if (error is TagoBusResponseException) {
      return error.message;
    }
    return '응답 파싱 실패';
  }
}
