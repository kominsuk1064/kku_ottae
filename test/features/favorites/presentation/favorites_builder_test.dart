import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/favorites/application/favorites_controller.dart';
import 'package:kku_ottae/features/favorites/application/favorites_providers.dart';
import 'package:kku_ottae/features/favorites/domain/favorite_repository.dart';
import 'package:kku_ottae/features/favorites/presentation/favorites_builder.dart';

void main() {
  group('FavoritesBuilder', () {
    testWidgets('복원된 상태를 전달하고 toggle 변경을 반영한다', (tester) async {
      final repository = _FakeFavoriteRepository(
        loadFavorites: () async => {'busroute:route-1'},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [favoriteRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(home: _FavoritesTestScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('즐겨찾기 1개'), findsOneWidget);

      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();

      expect(find.text('즐겨찾기 2개'), findsOneWidget);
      expect(repository.savedSnapshots.single, {
        'busroute:route-1',
        'busroute:route-2',
      });
    });

    testWidgets('복원 오류를 표시하고 스낵바에서 다시 시도한다', (tester) async {
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [favoriteRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            builder: (context, child) =>
                FavoritesErrorListener(child: child ?? const SizedBox.shrink()),
            home: _FavoritesTestScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(FavoritesController.loadErrorMessage), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(repository.loadRequestCount, 2);
      expect(find.text('즐겨찾기 1개'), findsOneWidget);
    });
  });
}

class _FavoritesTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FavoritesBuilder(
      builder: (context, favorites, toggleFavorite) => Scaffold(
        body: Column(
          children: [
            Text('즐겨찾기 ${favorites.length}개'),
            TextButton(
              onPressed: () => toggleFavorite('busroute:route-2'),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({
    required Future<Set<String>> Function() loadFavorites,
  }) : _loadFavorites = loadFavorites;

  final Future<Set<String>> Function() _loadFavorites;

  int loadRequestCount = 0;
  final List<Set<String>> savedSnapshots = [];

  @override
  Future<Set<String>> loadFavorites() {
    loadRequestCount++;
    return _loadFavorites();
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) async {
    savedSnapshots.add(Set<String>.unmodifiable(favorites));
  }
}
