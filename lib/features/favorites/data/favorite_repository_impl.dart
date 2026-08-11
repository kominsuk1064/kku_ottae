import '../domain/favorite_repository.dart';
import 'favorite_local_storage.dart';

final class FavoriteRepositoryImpl implements FavoriteRepository {
  const FavoriteRepositoryImpl(this._localStorage);

  final FavoriteLocalStorage _localStorage;

  @override
  Future<Set<String>> loadFavorites() async {
    final keys = await _localStorage.readFavoriteKeys();
    return Set<String>.unmodifiable(keys);
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) async {
    final keys = favorites.toList()..sort();
    await _localStorage.writeFavoriteKeys(keys);
  }
}
