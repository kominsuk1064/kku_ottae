import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/application/change_password_controller.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';
import 'package:kku_ottae/screens/change_password_screen.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('ChangePasswordScreen', () {
    testWidgets('빈 입력 오류를 화면에 표시하고 요청하지 않는다', (tester) async {
      final repository = FakeAuthRepository();
      await _pumpChangePasswordScreen(tester, repository);

      await tester.tap(find.byKey(const ValueKey('change-password-button')));
      await tester.pump();

      expect(
        find.text(ChangePasswordController.missingFieldsMessage),
        findsOneWidget,
      );
      expect(repository.changePasswordRequests, isEmpty);
    });

    testWidgets('변경 중 loading을 표시하고 성공하면 이전 화면으로 돌아간다', (tester) async {
      final response = Completer<void>();
      final repository = FakeAuthRepository(
        changePassword: (_, _) => response.future,
      );
      await _pumpChangePasswordScreen(tester, repository);
      await _enterPasswords(tester);

      final button = find.byKey(const ValueKey('change-password-button'));
      await tester.tap(button);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      response.complete();
      await tester.pumpAndSettle();

      expect(find.text('내 정보 화면'), findsOneWidget);
      expect(repository.changePasswordRequests.length, 1);
    });

    testWidgets('Firebase 오류를 사용자 메시지로 표시하고 화면을 유지한다', (tester) async {
      final repository = FakeAuthRepository(
        changePassword: (_, _) async => throw const AuthFailure(
          reason: AuthFailureReason.invalidCredential,
          debugMessage: 'firebase internal details',
        ),
      );
      await _pumpChangePasswordScreen(tester, repository);
      await _enterPasswords(tester);

      await tester.tap(find.byKey(const ValueKey('change-password-button')));
      await tester.pumpAndSettle();

      expect(find.text('현재 비밀번호가 올바르지 않습니다.'), findsOneWidget);
      expect(find.textContaining('firebase internal'), findsNothing);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('작은 화면에서도 비밀번호 폼을 스크롤할 수 있다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FakeAuthRepository();

      await _pumpChangePasswordScreen(tester, repository);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpChangePasswordScreen(
  WidgetTester tester,
  FakeAuthRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        routes: {
          '/': (_) => const _AccountScreen(),
          '/change-password': (_) => const ChangePasswordScreen(),
        },
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-change-password')));
  await tester.pumpAndSettle();
}

Future<void> _enterPasswords(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('current-password-field')),
    'current-password',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-password-field')),
    'new-password',
  );
  await tester.enterText(
    find.byKey(const ValueKey('confirm-password-field')),
    'new-password',
  );
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('내 정보 화면'),
          ElevatedButton(
            key: const ValueKey('open-change-password'),
            onPressed: () => Navigator.pushNamed(context, '/change-password'),
            child: const Text('비밀번호 변경 열기'),
          ),
        ],
      ),
    );
  }
}
