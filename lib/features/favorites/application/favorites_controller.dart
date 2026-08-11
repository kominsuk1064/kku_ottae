import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/favorite_repository.dart';
import 'favorites_providers.dart';
import 'favorites_state.dart';

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesState>(
      FavoritesController.new,
    );

final class FavoritesController extends Notifier<FavoritesState> {
  static const loadErrorMessage = '즐겨찾기를 불러오지 못했습니다.';
  static const saveErrorMessage = '즐겨찾기를 저장하지 못했습니다.';

  late final FavoriteRepository _repository;
  Future<void>? _loadOperation;
  Future<void>? _saveOperation;
  Set<String>? _pendingFavorites;
  bool _disposed = false;

  @override
  FavoritesState build() {
    _repository = ref.read(favoriteRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(load));
    return FavoritesState.loading();
  }

  Future<void> load() {
    if (_disposed) {
      return Future<void>.value();
    }

    final activeOperation = _loadOperation;
    if (activeOperation != null) {
      return activeOperation;
    }

    late final Future<void> operation;
    operation = _performLoad();
    _loadOperation = operation;
    return operation.whenComplete(() {
      if (identical(_loadOperation, operation)) {
        _loadOperation = null;
      }
    });
  }

  Future<void> toggle(String key) async {
    if (_disposed || key.isEmpty) {
      return;
    }

    if (state.status == FavoritesStatus.loading) {
      await load();
    }
    if (_disposed) {
      return;
    }

    final nextFavorites = Set<String>.of(state.favorites);
    if (!nextFavorites.remove(key)) {
      nextFavorites.add(key);
    }

    state = FavoritesState.ready(favorites: nextFavorites, isSaving: true);
    _pendingFavorites = state.favorites;
    await _scheduleSave();
  }

  Future<void> retry() {
    return switch (state.status) {
      FavoritesStatus.loadFailure => load(),
      FavoritesStatus.saveFailure => _retrySave(),
      FavoritesStatus.loading || FavoritesStatus.ready => Future<void>.value(),
    };
  }

  Future<void> _performLoad() async {
    state = FavoritesState.loading();
    try {
      final favorites = await _repository.loadFavorites();
      if (_disposed) {
        return;
      }
      state = FavoritesState.ready(favorites: favorites);
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      developer.log(
        '즐겨찾기 복원 실패',
        name: 'kku_ottae.favorites',
        error: error,
        stackTrace: stackTrace,
      );
      state = FavoritesState.loadFailure(message: loadErrorMessage);
    }
  }

  Future<void> _retrySave() {
    state = FavoritesState.ready(favorites: state.favorites, isSaving: true);
    _pendingFavorites = state.favorites;
    return _scheduleSave();
  }

  Future<void> _scheduleSave() {
    final activeOperation = _saveOperation;
    if (activeOperation != null) {
      return activeOperation;
    }

    late final Future<void> operation;
    operation = Future<void>.microtask(_drainPendingSaves);
    _saveOperation = operation;
    return operation.whenComplete(() {
      if (identical(_saveOperation, operation)) {
        _saveOperation = null;
      }
    });
  }

  Future<void> _drainPendingSaves() async {
    while (!_disposed) {
      final snapshot = _pendingFavorites;
      if (snapshot == null) {
        break;
      }
      _pendingFavorites = null;

      try {
        await _repository.saveFavorites(snapshot);
      } catch (error, stackTrace) {
        if (_disposed) {
          return;
        }
        _pendingFavorites = null;
        developer.log(
          '즐겨찾기 저장 실패',
          name: 'kku_ottae.favorites',
          error: error,
          stackTrace: stackTrace,
        );
        state = FavoritesState.saveFailure(
          favorites: state.favorites,
          message: saveErrorMessage,
        );
        return;
      }
    }

    if (!_disposed && state.isSaving) {
      state = FavoritesState.ready(favorites: state.favorites);
    }
  }
}
