abstract interface class FavoriteLocalStorage {
  Future<List<String>> readFavoriteKeys();

  Future<void> writeFavoriteKeys(List<String> keys);
}
