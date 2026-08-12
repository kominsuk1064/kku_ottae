import 'package:kku_ottae/core/observability/app_performance_monitor.dart';

final class FakeAppPerformanceMonitor implements AppPerformanceMonitor {
  FakeAppPerformanceMonitor({
    this.startError,
    this.traceMutationError,
    this.traceStopError,
  });

  final Object? startError;
  final Object? traceMutationError;
  final Object? traceStopError;
  final List<FakeAppPerformanceTrace> traces = [];

  @override
  Future<AppPerformanceTrace> startTrace(String name) async {
    final error = startError;
    if (error != null) {
      throw error;
    }

    final trace = FakeAppPerformanceTrace(
      name: name,
      mutationError: traceMutationError,
      stopError: traceStopError,
    );
    traces.add(trace);
    return trace;
  }
}

final class FakeAppPerformanceTrace implements AppPerformanceTrace {
  FakeAppPerformanceTrace({
    required this.name,
    this.mutationError,
    this.stopError,
  });

  final String name;
  final Object? mutationError;
  final Object? stopError;
  final Map<String, String> attributes = {};
  final Map<String, int> metrics = {};
  bool stopped = false;

  @override
  void putAttribute(String name, String value) {
    final error = mutationError;
    if (error != null) {
      throw error;
    }
    attributes[name] = value;
  }

  @override
  void setMetric(String name, int value) {
    final error = mutationError;
    if (error != null) {
      throw error;
    }
    metrics[name] = value;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    final error = stopError;
    if (error != null) {
      throw error;
    }
  }
}
