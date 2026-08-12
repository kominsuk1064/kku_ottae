import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/favorites/application/favorites_providers.dart';
import 'package:kku_ottae/features/favorites/domain/favorite_repository.dart';
import 'package:kku_ottae/screens/facility/facility_bar_screen.dart';
import 'package:kku_ottae/screens/facility/facility_cafe_screen.dart';
import 'package:kku_ottae/screens/facility/facility_etc_screen.dart';
import 'package:kku_ottae/screens/facility/facility_mart_screen.dart';
import 'package:kku_ottae/screens/facility/facility_pc_screen.dart';
import 'package:kku_ottae/screens/facility/facility_restaurant_screen.dart';
import 'package:kku_ottae/screens/facility/restaurant/restaurant_chicken_screen.dart';
import 'package:kku_ottae/screens/facility/restaurant/restaurant_china_screen.dart';
import 'package:kku_ottae/screens/facility/restaurant/restaurant_japan_screen.dart';
import 'package:kku_ottae/screens/facility/restaurant/restaurant_korea_screen.dart';
import 'package:kku_ottae/screens/facility/restaurant/restaurant_meat_screen.dart';
import 'package:kku_ottae/screens/facility_category_screen.dart';

void main() {
  group('FacilityCategoryScreen', () {
    testWidgets('320px 화면에서 한 열로 표시하고 마지막 카테고리까지 스크롤한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpFacilityCategories(tester);

      final grid = tester.widget<GridView>(
        find.descendant(
          of: find.byKey(const ValueKey('facility-category-grid')),
          matching: find.byType(GridView),
        ),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('facility-category-오락시설')),
        160,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('오락시설'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('넓은 화면에서 세 열과 콘텐츠 최대 너비를 적용한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpFacilityCategories(tester);

      final gridFinder = find.descendant(
        of: find.byKey(const ValueKey('facility-category-grid')),
        matching: find.byType(GridView),
      );
      final grid = tester.widget<GridView>(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 3);
      expect(tester.getSize(gridFinder).width, 720);
      expect(tester.takeException(), isNull);
    });

    testWidgets('여섯 카테고리의 실제 이동 경로를 유지한다', (tester) async {
      const navigationCases = <({String name, Type destination})>[
        (name: '식당', destination: FacilityRestaurantScreen),
        (name: '카페', destination: FacilityCafeScreen),
        (name: '술집', destination: FacilityBarScreen),
        (name: '편의점/마트', destination: FacilityMartScreen),
        (name: '기타 생활시설', destination: FacilityEtcScreen),
        (name: '오락시설', destination: FacilityPcScreen),
      ];

      for (final navigationCase in navigationCases) {
        await _pumpFacilityCategories(tester);
        final tile = find.byKey(
          ValueKey('facility-category-${navigationCase.name}'),
        );
        await tester.scrollUntilVisible(
          tile,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(tile);
        await tester.pumpAndSettle();

        expect(find.byType(navigationCase.destination), findsOneWidget);
      }
    });
  });

  group('FacilityRestaurantScreen', () {
    testWidgets('짧은 가로 화면에서 긴 소분류 이름을 overflow 없이 표시한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(568, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpRestaurantCategories(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('restaurant-category-족발/보쌈/고기/꼬치')),
        140,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('족발/보쌈/고기/꼬치'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('다섯 음식점 소분류의 실제 이동 경로를 유지한다', (tester) async {
      const navigationCases = <({String name, Type destination})>[
        (name: '한식', destination: RestaurantKoreaScreen),
        (name: '중식', destination: RestaurantChinaScreen),
        (name: '일식, 아시안', destination: RestaurantJapanScreen),
        (name: '치킨·피자·햄버거·토스트', destination: RestaurantChickenScreen),
        (name: '족발/보쌈/고기/꼬치', destination: RestaurantMeatScreen),
      ];

      for (final navigationCase in navigationCases) {
        await _pumpRestaurantCategories(tester);
        final tile = find.byKey(
          ValueKey('restaurant-category-${navigationCase.name}'),
        );
        await tester.scrollUntilVisible(
          tile,
          140,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(tile);
        await tester.pumpAndSettle();

        expect(find.byType(navigationCase.destination), findsOneWidget);
      }
    });
  });
}

Future<void> _pumpFacilityCategories(WidgetTester tester) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoriteRepositoryProvider.overrideWithValue(_FakeFavoriteRepository()),
      ],
      child: MaterialApp(
        key: UniqueKey(),
        home: const FacilityCategoryScreen(),
      ),
    ),
  );
}

Future<void> _pumpRestaurantCategories(WidgetTester tester) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoriteRepositoryProvider.overrideWithValue(_FakeFavoriteRepository()),
      ],
      child: MaterialApp(
        key: UniqueKey(),
        home: const FacilityRestaurantScreen(),
      ),
    ),
  );
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  @override
  Future<Set<String>> loadFavorites() async => {};

  @override
  Future<void> saveFavorites(Set<String> favorites) async {}
}
