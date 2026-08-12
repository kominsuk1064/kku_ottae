import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/application/login_controller.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';
import 'package:kku_ottae/screens/login_screen.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  const verifiedUser = AuthUser(
    id: 'user-1',
    email: 'student@kku.ac.kr',
    isEmailVerified: true,
  );

  group('LoginScreen', () {
    testWidgets('빈 입력 오류를 화면에 표시하고 요청하지 않는다', (tester) async {
      final repository = FakeAuthRepository();
      await _pumpLoginScreen(tester, repository);

      await tester.tap(find.byKey(const ValueKey('login-button')));
      await tester.pump();

      expect(
        find.text(LoginController.missingCredentialsMessage),
        findsOneWidget,
      );
      expect(repository.signInRequests, isEmpty);
    });

    testWidgets('로그인 중 loading을 표시하고 성공하면 홈으로 이동한다', (tester) async {
      final response = Completer<AuthUser>();
      final repository = FakeAuthRepository(signIn: (_, _) => response.future);
      await _pumpLoginScreen(tester, repository);
      await _enterCredentials(tester);

      await tester.tap(find.byKey(const ValueKey('login-button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const ValueKey('login-button')))
            .onPressed,
        isNull,
      );

      response.complete(verifiedUser);
      await tester.pumpAndSettle();

      expect(find.text('홈 화면'), findsOneWidget);
      expect(repository.signInRequests.length, 1);
    });

    testWidgets('로그인 오류를 화면에 표시하고 로그인 화면을 유지한다', (tester) async {
      final repository = FakeAuthRepository(
        signIn: (_, _) async => throw const AuthFailure(
          reason: AuthFailureReason.invalidCredential,
        ),
      );
      await _pumpLoginScreen(tester, repository);
      await _enterCredentials(tester);

      await tester.tap(find.byKey(const ValueKey('login-button')));
      await tester.pumpAndSettle();

      expect(find.text('이메일 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('이메일 미인증 상태를 표시하고 홈으로 이동하지 않는다', (tester) async {
      final repository = FakeAuthRepository(
        signIn: (_, _) async => const AuthUser(
          id: 'user-2',
          email: 'new@kku.ac.kr',
          isEmailVerified: false,
        ),
      );
      await _pumpLoginScreen(tester, repository);
      await _enterCredentials(tester);

      await tester.tap(find.byKey(const ValueKey('login-button')));
      await tester.pumpAndSettle();

      expect(find.text(LoginController.emailUnverifiedMessage), findsOneWidget);
      expect(find.text('홈 화면'), findsNothing);
    });

    testWidgets('비밀번호 재설정 중 loading을 표시하고 완료 메시지를 보여준다', (tester) async {
      final response = Completer<void>();
      final repository = FakeAuthRepository(
        sendPasswordResetEmail: (_) => response.future,
      );
      await _pumpLoginScreen(tester, repository);
      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'student@kku.ac.kr',
      );

      await tester.tap(find.byKey(const ValueKey('password-reset-button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('password-reset-button')),
            )
            .onPressed,
        isNull,
      );

      response.complete();
      await tester.pumpAndSettle();

      expect(
        find.text(LoginController.passwordResetSentMessage),
        findsOneWidget,
      );
      expect(repository.passwordResetRequests, ['student@kku.ac.kr']);
    });

    testWidgets('작은 화면에서도 로그인 폼이 스크롤 가능한 상태로 렌더링된다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FakeAuthRepository();

      await _pumpLoginScreen(tester, repository);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpLoginScreen(
  WidgetTester tester,
  FakeAuthRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        routes: {
          '/': (_) => const LoginScreen(),
          '/home': (_) => const Scaffold(body: Center(child: Text('홈 화면'))),
        },
      ),
    ),
  );
  await tester.pump();
}

Future<void> _enterCredentials(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('login-email-field')),
    'student@kku.ac.kr',
  );
  await tester.enterText(
    find.byKey(const ValueKey('login-password-field')),
    'password',
  );
}
