import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/favorites/data/shared_preferences_favorite_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesFavoriteLocalStorage', () {
    test('저장된 값이 없으면 빈 목록을 반환한다', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = SharedPreferences.getInstance();
      final storage = SharedPreferencesFavoriteLocalStorage(
        preferences: preferences,
      );

      final keys = await storage.readFavoriteKeys();

      expect(keys, isEmpty);
    });

    test('기존 favorites 키의 값을 복원한다', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesFavoriteLocalStorage.storageKey: <String>[
          'busroute:route-1',
          'restaurant:학생회관|라면|1층',
        ],
      });
      final preferences = SharedPreferences.getInstance();
      final storage = SharedPreferencesFavoriteLocalStorage(
        preferences: preferences,
      );

      final keys = await storage.readFavoriteKeys();

      expect(keys, ['busroute:route-1', 'restaurant:학생회관|라면|1층']);
      expect(() => keys.add('new-key'), throwsUnsupportedError);
    });

    test('기존 favorites 키에 값을 저장한다', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = SharedPreferences.getInstance();
      final storage = SharedPreferencesFavoriteLocalStorage(
        preferences: preferences,
      );

      await storage.writeFavoriteKeys([
        'busroute:route-1',
        'restaurant:학생회관|라면|1층',
      ]);

      expect(
        (await preferences).getStringList(
          SharedPreferencesFavoriteLocalStorage.storageKey,
        ),
        ['busroute:route-1', 'restaurant:학생회관|라면|1층'],
      );
    });
  });
}
