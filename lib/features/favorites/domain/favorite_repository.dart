abstract interface class FavoriteRepository {
  Future<Set<String>> loadFavorites();

  Future<void> saveFavorites(Set<String> favorites);
}
