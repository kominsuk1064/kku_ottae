import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/favorite_repository_impl.dart';
import '../data/shared_preferences_favorite_local_storage.dart';
import '../domain/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(SharedPreferencesFavoriteLocalStorage());
});
