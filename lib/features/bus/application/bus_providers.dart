import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/observability/app_performance_monitor.dart';
import '../data/tago_bus_arrival_repository.dart';
import '../domain/bus_arrival_repository.dart';

final class BusRepositoryConfiguration {
  const BusRepositoryConfiguration({
    required this.serviceKey,
    required this.cityCode,
  });

  final String serviceKey;
  final String cityCode;
}

typedef BusArrivalRepositoryFactory =
    BusArrivalRepository Function(BusRepositoryConfiguration configuration);
typedef BusClock = DateTime Function();
typedef BusPeriodicTimerFactory =
    Timer Function(Duration duration, void Function(Timer timer) callback);

final busArrivalRepositoryFactoryProvider =
    Provider<BusArrivalRepositoryFactory>((ref) {
      final performanceMonitor = ref.watch(appPerformanceMonitorProvider);
      return (configuration) => TagoBusArrivalRepository.live(
        serviceKey: configuration.serviceKey,
        cityCode: configuration.cityCode,
        performanceMonitor: performanceMonitor,
      );
    });

final busClockProvider = Provider<BusClock>((ref) => DateTime.now);

final busPollingIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 15),
);

final busPeriodicTimerFactoryProvider = Provider<BusPeriodicTimerFactory>(
  (ref) =>
      (duration, callback) => Timer.periodic(duration, callback),
);
