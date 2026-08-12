import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/screens/initial_screen.dart';

void main() {
  group('InitialScreen', () {
    testWidgets('작은 세로 화면에서 모든 동작을 overflow 없이 표시한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(tester);

      expect(find.byKey(const ValueKey('initial-scroll-view')), findsOneWidget);
      expect(find.byKey(const ValueKey('initial-logo')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('initial-login-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('initial-join-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('짧은 가로 화면에서 회원가입 버튼까지 스크롤할 수 있다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(568, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('initial-join-button')),
        120,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byKey(const ValueKey('initial-join-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('로그인과 회원가입 이동 경로를 유지한다', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('initial-login-button')));
      await tester.pumpAndSettle();
      expect(find.text('로그인 화면'), findsOneWidget);

      await _pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('initial-join-button')));
      await tester.pumpAndSettle();
      expect(find.text('회원가입 화면'), findsOneWidget);
    });
  });
}

Future<void> _pumpScreen(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      routes: {
        '/': (_) => const InitialScreen(),
        '/login': (_) => const Scaffold(body: Text('로그인 화면')),
        '/join': (_) => const Scaffold(body: Text('회원가입 화면')),
      },
    ),
  );
}
