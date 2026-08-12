import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('작은 세로 화면에서 홈 메뉴를 overflow 없이 표시한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(tester);

      expect(find.byKey(const ValueKey('home-scroll-view')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-profile-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-bus-button')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-facility-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('home-map-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('짧은 가로 화면에서 학교지도 메뉴까지 스크롤할 수 있다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(568, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-map-button')),
        160,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byKey(const ValueKey('home-map-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('프로필과 세 개 홈 메뉴의 이동 경로를 유지한다', (tester) async {
      const navigationCases = <({Key buttonKey, String destination})>[
        (buttonKey: ValueKey('home-profile-button'), destination: '내 정보 화면'),
        (buttonKey: ValueKey('home-bus-button'), destination: '버스 화면'),
        (buttonKey: ValueKey('home-facility-button'), destination: '편의시설 화면'),
        (buttonKey: ValueKey('home-map-button'), destination: '학교지도 화면'),
      ];

      for (final navigationCase in navigationCases) {
        await _pumpScreen(tester);
        await tester.tap(find.byKey(navigationCase.buttonKey));
        await tester.pumpAndSettle();

        expect(find.text(navigationCase.destination), findsOneWidget);
      }
    });
  });
}

Future<void> _pumpScreen(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      routes: {
        '/': (_) => HomeScreen(
          campusMapBuilder: (_) => const _Destination(label: '학교지도 화면'),
        ),
        '/mypage': (_) => const _Destination(label: '내 정보 화면'),
        '/bus': (_) => const _Destination(label: '버스 화면'),
        '/facility': (_) => const _Destination(label: '편의시설 화면'),
      },
    ),
  );
}

class _Destination extends StatelessWidget {
  const _Destination({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
