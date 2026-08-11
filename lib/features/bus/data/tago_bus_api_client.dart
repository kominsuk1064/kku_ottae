import 'dart:async';

import 'package:http/http.dart' as http;

import 'tago_bus_exception.dart';
import 'tago_bus_parser.dart';

class TagoBusApiClient {
  TagoBusApiClient({
    required http.Client client,
    TagoBusParser parser = const TagoBusParser(),
    this.requestTimeout = const Duration(seconds: 8),
  }) : _client = client,
       _parser = parser;

  factory TagoBusApiClient.live({
    Duration requestTimeout = const Duration(seconds: 8),
  }) {
    return TagoBusApiClient(
      client: http.Client(),
      requestTimeout: requestTimeout,
    );
  }

  static const _arrivalEndpoint =
      'https://apis.data.go.kr/1613000/ArvlInfoInqireService/'
      'getSttnAcctoArvlPrearngeInfoList';
  static const _routesEndpoint =
      'https://apis.data.go.kr/1613000/BusRouteInfoInqireService/'
      'getSttnThrghRouteList';

  final http.Client _client;
  final TagoBusParser _parser;
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
    return _getItems(uri);
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
    return _getItems(uri);
  }

  Future<List<Map<String, dynamic>>> _getItems(Uri uri) async {
    final response = await _client.get(uri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw TagoBusHttpException(response.statusCode);
    }

    return _parser.parseItems(response.body);
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
