import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/core/observability/app_error_reporter.dart';
import 'package:kku_ottae/features/favorites/application/favorites_controller.dart';
import 'package:kku_ottae/features/favorites/application/favorites_providers.dart';
import 'package:kku_ottae/features/favorites/application/favorites_state.dart';
import 'package:kku_ottae/features/favorites/domain/favorite_repository.dart';

import '../../../support/fake_app_error_reporter.dart';

void main() {
  group('FavoritesController', () {
    test('loading 상태에서 저장된 즐겨찾기를 복원한다', () async {
      final repository = _FakeFavoriteRepository(
        loadFavorites: () async => {'busroute:route-1'},
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.states.first.status, FavoritesStatus.loading);
      expect(harness.readState().status, FavoritesStatus.ready);
      expect(harness.readState().favorites, {'busroute:route-1'});
      expect(
        () => harness.readState().favorites.add('new-key'),
        throwsUnsupportedError,
      );
    });

    test('복원 실패 상태에서 다시 시도하면 정상 상태로 복구한다', () async {
      final errorReporter = FakeAppErrorReporter();
      var shouldFail = true;
      final repository = _FakeFavoriteRepository(
        loadFavorites: () async {
          if (shouldFail) {
            shouldFail = false;
            throw StateError('load failed');
          }
          return {'busroute:route-1'};
        },
      );
      final harness = _createHarness(repository, errorReporter: errorReporter);
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.readState().status, FavoritesStatus.loadFailure);
      expect(
        harness.readState().errorMessage,
        FavoritesController.loadErrorMessage,
      );
      expect(errorReporter.reports, hasLength(1));
      expect(errorReporter.reports.single.reason, 'Favorites restore failed');
      expect(errorReporter.reports.single.fatal, isFalse);

      await harness.readController().retry();

      expect(harness.readState().status, FavoritesStatus.ready);
      expect(harness.readState().favorites, {'busroute:route-1'});
      expect(repository.loadRequestCount, 2);
    });

    test('즐겨찾기를 추가하고 변경된 전체 상태를 저장한다', () async {
      final repository = _FakeFavoriteRepository();
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);
      await _settle(harness.container);

      await harness.readController().toggle('busroute:route-1');

      expect(harness.readState().status, FavoritesStatus.ready);
      expect(harness.readState().favorites, {'busroute:route-1'});
      expect(repository.savedSnapshots, [
        {'busroute:route-1'},
      ]);
    });

    test('즐겨찾기를 삭제하고 남은 상태를 저장한다', () async {
      final repository = _FakeFavoriteRepository(
        loadFavorites: () async => {
          'busroute:route-1',
          'restaurant:학생회관|라면|1층',
        },
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);
      await _settle(harness.container);

      await harness.readController().toggle('busroute:route-1');

      expect(harness.readState().favorites, {'restaurant:학생회관|라면|1층'});
      expect(repository.savedSnapshots, [
        {'restaurant:학생회관|라면|1층'},
      ]);
    });

    test('복원 중 발생한 변경을 복원 결과와 합쳐 저장한다', () async {
      final loadResponse = Completer<Set<String>>();
      final repository = _FakeFavoriteRepository(
        loadFavorites: () => loadResponse.future,
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      final toggle = harness.readController().toggle('busroute:route-2');
      loadResponse.complete({'busroute:route-1'});
      await toggle;

      expect(harness.readState().favorites, {
        'busroute:route-1',
        'busroute:route-2',
      });
      expect(repository.savedSnapshots.single, {
        'busroute:route-1',
        'busroute:route-2',
      });
    });

    test('연속 변경의 저장을 직렬화하고 최신 상태까지 반영한다', () async {
      final firstSave = Completer<void>();
      var saveCount = 0;
      final repository = _FakeFavoriteRepository(
        saveFavorites: (_) {
          saveCount++;
          return saveCount == 1 ? firstSave.future : Future<void>.value();
        },
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);
      await _settle(harness.container);

      final firstToggle = harness.readController().toggle('busroute:route-1');
      await _settle(harness.container);
      final secondToggle = harness.readController().toggle(
        'restaurant:학생회관|라면|1층',
      );

      expect(repository.savedSnapshots.length, 1);
      expect(harness.readState().isSaving, isTrue);

      firstSave.complete();
      await Future.wait([firstToggle, secondToggle]);

      expect(repository.savedSnapshots, [
        {'busroute:route-1'},
        {'busroute:route-1', 'restaurant:학생회관|라면|1층'},
      ]);
      expect(harness.readState().favorites, {
        'busroute:route-1',
        'restaurant:학생회관|라면|1층',
      });
      expect(harness.readState().isSaving, isFalse);
    });

    test('저장 실패 시 선택을 유지하고 다시 시도로 저장한다', () async {
      final errorReporter = FakeAppErrorReporter();
      var shouldFail = true;
      final repository = _FakeFavoriteRepository(
        saveFavorites: (_) async {
          if (shouldFail) {
            shouldFail = false;
            throw StateError('save failed');
          }
        },
      );
      final harness = _createHarness(repository, errorReporter: errorReporter);
      addTearDown(harness.dispose);
      await _settle(harness.container);

      await harness.readController().toggle('busroute:route-1');

      expect(harness.readState().status, FavoritesStatus.saveFailure);
      expect(harness.readState().favorites, {'busroute:route-1'});
      expect(
        harness.readState().errorMessage,
        FavoritesController.saveErrorMessage,
      );
      expect(errorReporter.reports, hasLength(1));
      expect(
        errorReporter.reports.single.reason,
        'Favorites persistence failed',
      );
      expect(errorReporter.reports.single.fatal, isFalse);

      await harness.readController().retry();

      expect(harness.readState().status, FavoritesStatus.ready);
      expect(harness.readState().favorites, {'busroute:route-1'});
      expect(repository.savedSnapshots.length, 2);
    });
  });
}

_ControllerHarness _createHarness(
  _FakeFavoriteRepository repository, {
  FakeAppErrorReporter? errorReporter,
}) {
  final reporter = errorReporter ?? FakeAppErrorReporter();
  final container = ProviderContainer(
    overrides: [
      appErrorReporterProvider.overrideWithValue(reporter),
      favoriteRepositoryProvider.overrideWithValue(repository),
    ],
  );
  final states = <FavoritesState>[];
  final subscription = container.listen(
    favoritesControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _ControllerHarness(
    container: container,
    subscription: subscription,
    states: states,
  );
}

Future<void> _settle(ProviderContainer container) async {
  for (var index = 0; index < 5; index++) {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
  }
}

final class _ControllerHarness {
  const _ControllerHarness({
    required this.container,
    required this.subscription,
    required this.states,
  });

  final ProviderContainer container;
  final ProviderSubscription<FavoritesState> subscription;
  final List<FavoritesState> states;

  FavoritesState readState() => container.read(favoritesControllerProvider);

  FavoritesController readController() {
    return container.read(favoritesControllerProvider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({
    Future<Set<String>> Function()? loadFavorites,
    Future<void> Function(Set<String> favorites)? saveFavorites,
  }) : _loadFavorites = loadFavorites ?? _emptyFavorites,
       _saveFavorites = saveFavorites ?? _saveSuccessfully;

  final Future<Set<String>> Function() _loadFavorites;
  final Future<void> Function(Set<String> favorites) _saveFavorites;

  int loadRequestCount = 0;
  final List<Set<String>> savedSnapshots = [];

  @override
  Future<Set<String>> loadFavorites() {
    loadRequestCount++;
    return _loadFavorites();
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) {
    final snapshot = Set<String>.unmodifiable(favorites);
    savedSnapshots.add(snapshot);
    return _saveFavorites(snapshot);
  }

  static Future<Set<String>> _emptyFavorites() async => const {};

  static Future<void> _saveSuccessfully(Set<String> _) async {}
}
