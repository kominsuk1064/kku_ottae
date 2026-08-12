import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/screens/facility/facility_cafe_screen.dart';
import 'package:kku_ottae/screens/facility/widgets/facility_place_list.dart';

void main() {
  group('FacilityPlaceList', () {
    testWidgets('320px 화면에서 긴 상호명과 주소를 overflow 없이 표시한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var toggleCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacilityPlaceList(
              sections: [
                FacilitySection(
                  title: '신촌 · 단월',
                  children: [
                    FacilityPlaceCard(
                      name: '아주 긴 편의시설 상호명이 여러 줄로 표시되는 장소',
                      menu: '카페, 디저트, 밀크티',
                      location: '충북 충주시 아주 긴 도로명 주소 123 학생회관 지하 1층',
                      isFavorited: false,
                      onFavoriteToggle: () => toggleCount++,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('아주 긴 편의시설 상호명이 여러 줄로 표시되는 장소'), findsOneWidget);
      expect(find.text('충북 충주시 아주 긴 도로명 주소 123 학생회관 지하 1층'), findsOneWidget);
      expect(find.byTooltip('즐겨찾기 추가'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('즐겨찾기 추가'));
      expect(toggleCount, 1);
    });

    testWidgets('넓은 화면에서 목록 콘텐츠 너비를 제한한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacilityPlaceList(
              sections: [
                FacilitySection(
                  title: '구역',
                  children: [
                    FacilityPlaceCard(
                      name: '장소',
                      location: '주소',
                      isFavorited: true,
                      onFavoriteToggle: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(Card)).width, 720);
      expect(find.byTooltip('즐겨찾기 삭제'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('FacilityCafeScreen', () {
    testWidgets('짧은 가로 화면에서 목록 스크롤과 기존 즐겨찾기 키를 유지한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(568, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? toggledKey;

      await tester.pumpWidget(
        MaterialApp(
          home: FacilityCafeScreen(
            favorites: const {},
            toggleFavorite: (key) => toggledKey = key,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('facility-favorite-메가MGC커피')));
      expect(toggledKey, 'restaurant-메가MGC커피|카페|충북 충주시 충열5길 24 1층');

      await tester.scrollUntilVisible(
        find.text('카페일노베'),
        160,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('카페일노베'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
