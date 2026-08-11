import 'dart:convert';

import 'tago_bus_exception.dart';

class TagoBusParser {
  const TagoBusParser();

  List<Map<String, dynamic>> parseItems(String responseBody) {
    final text = responseBody.trim();

    if (text.startsWith('<')) {
      final message = text.contains('Policy Falsified')
          ? 'API 거부: 키/엔드포인트/파라미터 확인'
          : 'API XML 오류 응답';
      throw TagoBusResponseException(message);
    }

    final decoded = jsonDecode(text);
    return extractItems(decoded);
  }

  List<Map<String, dynamic>> extractItems(Object? body) {
    if (body is List) {
      return _mapsOnly(body);
    }

    if (body is! Map) {
      return const [];
    }

    final response = body['response'];
    final responseBody = response is Map ? response['body'] : null;
    final totalCount = responseBody is Map ? responseBody['totalCount'] : null;

    if (_isZero(totalCount)) {
      return const [];
    }

    final items = responseBody is Map ? responseBody['items'] : null;
    final item = items is Map ? items['item'] : null;

    if (item is List) {
      return _mapsOnly(item);
    }

    final singleItem = _toStringKeyedMap(item);
    return singleItem == null ? const [] : [singleItem];
  }

  bool _isZero(Object? value) {
    if (value is num) {
      return value == 0;
    }
    return value?.toString() == '0';
  }

  List<Map<String, dynamic>> _mapsOnly(Iterable<Object?> values) {
    return values
        .map(_toStringKeyedMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Map<String, dynamic>? _toStringKeyedMap(Object? value) {
    if (value is! Map) {
      return null;
    }

    return value.map((key, itemValue) => MapEntry(key.toString(), itemValue));
  }
}
