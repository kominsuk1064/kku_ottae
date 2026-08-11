import 'package:shared_preferences/shared_preferences.dart';

import 'favorite_local_storage.dart';
import 'favorite_storage_exception.dart';

final class SharedPreferencesFavoriteLocalStorage
    implements FavoriteLocalStorage {
  SharedPreferencesFavoriteLocalStorage({
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const storageKey = 'favorites';

  final Future<SharedPreferences> _preferences;

  @override
  Future<List<String>> readFavoriteKeys() async {
    final preferences = await _preferences;
    final keys = preferences.getStringList(storageKey) ?? const <String>[];
    return List<String>.unmodifiable(keys);
  }

  @override
  Future<void> writeFavoriteKeys(List<String> keys) async {
    final preferences = await _preferences;
    final saved = await preferences.setStringList(
      storageKey,
      List<String>.unmodifiable(keys),
    );
    if (!saved) {
      throw const FavoriteStorageException('즐겨찾기를 로컬 저장소에 저장하지 못했습니다.');
    }
  }
}
