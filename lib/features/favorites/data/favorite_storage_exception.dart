final class FavoriteStorageException implements Exception {
  const FavoriteStorageException(this.message);

  final String message;

  @override
  String toString() => 'FavoriteStorageException: $message';
}
