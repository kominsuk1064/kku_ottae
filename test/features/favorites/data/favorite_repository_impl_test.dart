import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/favorites/data/favorite_local_storage.dart';
import 'package:kku_ottae/features/favorites/data/favorite_repository_impl.dart';

void main() {
  group('FavoriteRepositoryImpl', () {
    test('중복을 제거한 불변 Set으로 복원한다', () async {
      final storage = _FakeFavoriteLocalStorage([
        'busroute:route-1',
        'busroute:route-1',
        'restaurant:학생회관|라면|1층',
      ]);
      final repository = FavoriteRepositoryImpl(storage);

      final favorites = await repository.loadFavorites();

      expect(favorites, {'busroute:route-1', 'restaurant:학생회관|라면|1층'});
      expect(() => favorites.add('new-key'), throwsUnsupportedError);
    });

    test('추가된 즐겨찾기를 기존 항목과 함께 저장한다', () async {
      final storage = _FakeFavoriteLocalStorage(['busroute:route-1']);
      final repository = FavoriteRepositoryImpl(storage);
      final favorites = await repository.loadFavorites();

      await repository.saveFavorites({...favorites, 'restaurant:학생회관|라면|1층'});

      expect(storage.storedKeys, ['busroute:route-1', 'restaurant:학생회관|라면|1층']);
    });

    test('삭제된 즐겨찾기를 제외하고 저장한다', () async {
      final storage = _FakeFavoriteLocalStorage([
        'busroute:route-1',
        'restaurant:학생회관|라면|1층',
      ]);
      final repository = FavoriteRepositoryImpl(storage);
      final favorites = Set<String>.of(await repository.loadFavorites())
        ..remove('busroute:route-1');

      await repository.saveFavorites(favorites);

      expect(storage.storedKeys, ['restaurant:학생회관|라면|1층']);
    });

    test('로컬 저장소 오류를 호출자에게 전달한다', () async {
      final failure = StateError('write failed');
      final storage = _FakeFavoriteLocalStorage([], writeError: failure);
      final repository = FavoriteRepositoryImpl(storage);

      await expectLater(
        repository.saveFavorites({'busroute:route-1'}),
        throwsA(same(failure)),
      );
    });
  });
}

final class _FakeFavoriteLocalStorage implements FavoriteLocalStorage {
  _FakeFavoriteLocalStorage(List<String> initialKeys, {this.writeError})
    : storedKeys = List<String>.of(initialKeys);

  List<String> storedKeys;
  final Object? writeError;

  @override
  Future<List<String>> readFavoriteKeys() async {
    return List<String>.of(storedKeys);
  }

  @override
  Future<void> writeFavoriteKeys(List<String> keys) async {
    if (writeError case final error?) {
      throw error;
    }
    storedKeys = List<String>.of(keys);
  }
}
