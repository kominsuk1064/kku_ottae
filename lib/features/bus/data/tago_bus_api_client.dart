import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/observability/app_performance_monitor.dart';
import 'tago_bus_exception.dart';
import 'tago_bus_parser.dart';

class TagoBusApiClient {
  TagoBusApiClient({
    required http.Client client,
    TagoBusParser parser = const TagoBusParser(),
    AppPerformanceMonitor performanceMonitor =
        const NoOpAppPerformanceMonitor(),
    this.requestTimeout = const Duration(seconds: 8),
  }) : _client = client,
       _parser = parser,
       _performanceMonitor = performanceMonitor;

  factory TagoBusApiClient.live({
    AppPerformanceMonitor performanceMonitor =
        const NoOpAppPerformanceMonitor(),
    Duration requestTimeout = const Duration(seconds: 8),
  }) {
    return TagoBusApiClient(
      client: http.Client(),
      performanceMonitor: performanceMonitor,
      requestTimeout: requestTimeout,
    );
  }

  static const performanceTraceName = 'tago_bus_request';

  static const _arrivalEndpoint =
      'https://apis.data.go.kr/1613000/ArvlInfoInqireService/'
      'getSttnAcctoArvlPrearngeInfoList';
  static const _routesEndpoint =
      'https://apis.data.go.kr/1613000/BusRouteInfoInqireService/'
      'getSttnThrghRouteList';

  final http.Client _client;
  final TagoBusParser _parser;
  final AppPerformanceMonitor _performanceMonitor;
  final Duration requestTimeout;

  Future<List<Map<String, dynamic>>> fetchArrivals({
    required String serviceKey,
    required String cityCode,
    required String stopId,
  }) {
    final uri = _buildUri(
      endpoint: _arrivalEndpoint,
      serviceKey: serviceKey,
      cityCode: cityCode,
      stopId: stopId,
      nodeParameter: 'nodeId',
      rows: 30,
    );
    return _getItems(uri, operation: 'arrivals');
  }

  Future<List<Map<String, dynamic>>> fetchRoutesThroughStop({
    required String serviceKey,
    required String cityCode,
    required String stopId,
  }) {
    final uri = _buildUri(
      endpoint: _routesEndpoint,
      serviceKey: serviceKey,
      cityCode: cityCode,
      stopId: stopId,
      nodeParameter: 'nodeid',
      rows: 100,
    );
    return _getItems(uri, operation: 'routes');
  }

  Future<List<Map<String, dynamic>>> _getItems(
    Uri uri, {
    required String operation,
  }) async {
    final trace = await _performanceMonitor.startTrace(performanceTraceName);
    trace.putAttribute('operation', operation);

    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      trace.putAttribute('http_status', response.statusCode.toString());
      trace.setMetric('response_bytes', response.bodyBytes.length);

      if (response.statusCode != 200) {
        trace.putAttribute('outcome', 'http_error');
        throw TagoBusHttpException(response.statusCode);
      }

      final items = _parser.parseItems(response.body);
      trace.putAttribute('outcome', items.isEmpty ? 'empty' : 'success');
      trace.setMetric('item_count', items.length);
      return items;
    } on TimeoutException {
      trace.putAttribute('outcome', 'timeout');
      rethrow;
    } on TagoBusHttpException {
      rethrow;
    } on TagoBusResponseException {
      trace.putAttribute('outcome', 'invalid_response');
      rethrow;
    } on FormatException {
      trace.putAttribute('outcome', 'invalid_response');
      rethrow;
    } on http.ClientException {
      trace.putAttribute('outcome', 'network_error');
      rethrow;
    } catch (_) {
      trace.putAttribute('outcome', 'unexpected_error');
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  Uri _buildUri({
    required String endpoint,
    required String serviceKey,
    required String cityCode,
    required String stopId,
    required String nodeParameter,
    required int rows,
  }) {
    final encodedKey = serviceKey.contains('%')
        ? serviceKey
        : Uri.encodeComponent(serviceKey);
    final encodedCityCode = Uri.encodeComponent(cityCode);
    final encodedStopId = Uri.encodeComponent(stopId);

    return Uri.parse(
      '$endpoint?serviceKey=$encodedKey&_type=json'
      '&cityCode=$encodedCityCode&$nodeParameter=$encodedStopId'
      '&pageNo=1&numOfRows=$rows',
    );
  }

  void dispose() => _client.close();
}
