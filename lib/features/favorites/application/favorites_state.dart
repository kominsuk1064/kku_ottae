enum FavoritesStatus { loading, ready, loadFailure, saveFailure }

final class FavoritesState {
  FavoritesState._({
    required this.status,
    required Set<String> favorites,
    required this.isSaving,
    required this.errorMessage,
  }) : favorites = Set<String>.unmodifiable(favorites);

  factory FavoritesState.loading() {
    return FavoritesState._(
      status: FavoritesStatus.loading,
      favorites: const {},
      isSaving: false,
      errorMessage: null,
    );
  }

  factory FavoritesState.ready({
    required Set<String> favorites,
    bool isSaving = false,
  }) {
    return FavoritesState._(
      status: FavoritesStatus.ready,
      favorites: favorites,
      isSaving: isSaving,
      errorMessage: null,
    );
  }

  factory FavoritesState.loadFailure({required String message}) {
    return FavoritesState._(
      status: FavoritesStatus.loadFailure,
      favorites: const {},
      isSaving: false,
      errorMessage: message,
    );
  }

  factory FavoritesState.saveFailure({
    required Set<String> favorites,
    required String message,
  }) {
    return FavoritesState._(
      status: FavoritesStatus.saveFailure,
      favorites: favorites,
      isSaving: false,
      errorMessage: message,
    );
  }

  final FavoritesStatus status;
  final Set<String> favorites;
  final bool isSaving;
  final String? errorMessage;

  bool contains(String key) => favorites.contains(key);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FavoritesState &&
            status == other.status &&
            _setEquals(favorites, other.favorites) &&
            isSaving == other.isSaving &&
            errorMessage == other.errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      Object.hashAllUnordered(favorites),
      isSaving,
      errorMessage,
    );
  }
}

bool _setEquals<T>(Set<T> first, Set<T> second) {
  return identical(first, second) ||
      first.length == second.length && first.containsAll(second);
}
