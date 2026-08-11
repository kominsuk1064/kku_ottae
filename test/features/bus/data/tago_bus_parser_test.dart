import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_exception.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_parser.dart';

void main() {
  const parser = TagoBusParser();

  group('TagoBusParser', () {
    test('parses a top-level list', () {
      final items = parser.parseItems('[{"routeid":"CHB1","routeno":"100"}]');

      expect(items, hasLength(1));
      expect(items.single['routeid'], 'CHB1');
    });

    test('parses a nested item list', () {
      final items = parser.parseItems('''
        {
          "response": {
            "body": {
              "totalCount": 2,
              "items": {
                "item": [
                  {"routeid": "CHB1", "routeno": "100"},
                  {"routeid": "CHB2", "routeno": "200"}
                ]
              }
            }
          }
        }
      ''');

      expect(items.map((item) => item['routeno']), ['100', '200']);
    });

    test('wraps a nested single item map in a list', () {
      final items = parser.parseItems('''
        {
          "response": {
            "body": {
              "totalCount": 1,
              "items": {
                "item": {"routeid": "CHB1", "routeno": "100"}
              }
            }
          }
        }
      ''');

      expect(items, [
        {'routeid': 'CHB1', 'routeno': '100'},
      ]);
    });

    test('returns an empty list when item is null', () {
      final items = parser.parseItems('''
        {
          "response": {
            "body": {
              "totalCount": 1,
              "items": {"item": null}
            }
          }
        }
      ''');

      expect(items, isEmpty);
    });

    test('returns an empty list when the response body is null', () {
      expect(parser.parseItems('null'), isEmpty);
    });

    test('returns an empty list when totalCount is zero', () {
      final items = parser.parseItems('''
        {
          "response": {
            "body": {
              "totalCount": 0,
              "items": null
            }
          }
        }
      ''');

      expect(items, isEmpty);
    });

    test('reports a policy failure returned as XML', () {
      expect(
        () => parser.parseItems(
          '<OpenAPI_ServiceResponse>'
          'Policy Falsified'
          '</OpenAPI_ServiceResponse>',
        ),
        throwsA(
          isA<TagoBusResponseException>().having(
            (error) => error.message,
            'message',
            'API 거부: 키/엔드포인트/파라미터 확인',
          ),
        ),
      );
    });
  });
}
