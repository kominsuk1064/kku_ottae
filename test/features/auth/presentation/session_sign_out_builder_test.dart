import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';
import 'package:kku_ottae/features/auth/presentation/session_sign_out_builder.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('SessionSignOutBuilder', () {
    testWidgets('로그아웃 중 loading을 표시하고 완료 후 초기 화면으로 이동한다', (tester) async {
      final response = Completer<void>();
      final repository = FakeAuthRepository(signOut: () => response.future);
      await _pumpSessionScreen(tester, repository);

      final button = find.byKey(const ValueKey('sign-out-button'));
      await tester.tap(button);
      await tester.pump();

      expect(find.text('로그아웃 중...'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      response.complete();
      await tester.pumpAndSettle();

      expect(find.text('초기 화면'), findsOneWidget);
      expect(repository.signOutRequestCount, 1);
    });

    testWidgets('로그아웃 실패 시 화면을 유지하고 스낵바에서 다시 시도한다', (tester) async {
      var shouldFail = true;
      final repository = FakeAuthRepository(
        signOut: () async {
          if (shouldFail) {
            shouldFail = false;
            throw const AuthFailure(
              reason: AuthFailureReason.networkUnavailable,
            );
          }
        },
      );
      await _pumpSessionScreen(tester, repository);

      await tester.tap(find.byKey(const ValueKey('sign-out-button')));
      await tester.pumpAndSettle();

      expect(find.text('네트워크 연결을 확인해주세요.'), findsOneWidget);
      expect(find.text('세션 화면'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.text('초기 화면'), findsOneWidget);
      expect(repository.signOutRequestCount, 2);
    });
  });
}

Future<void> _pumpSessionScreen(
  WidgetTester tester,
  FakeAuthRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        routes: {
          '/': (_) => const _SessionScreen(),
          '/signed-out': (_) =>
              const Scaffold(body: Center(child: Text('초기 화면'))),
        },
      ),
    ),
  );
  await tester.pump();
}

class _SessionScreen extends StatelessWidget {
  const _SessionScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('세션 화면'),
          SessionSignOutBuilder(
            onSignedOut: () =>
                Navigator.pushReplacementNamed(context, '/signed-out'),
            builder: (context, state, signOut) => ElevatedButton(
              key: const ValueKey('sign-out-button'),
              onPressed: state.isSigningOut ? null : signOut,
              child: Text(state.isSigningOut ? '로그아웃 중...' : '로그아웃'),
            ),
          ),
        ],
      ),
    );
  }
}
