import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/application/login_controller.dart';
import 'package:kku_ottae/features/auth/application/login_state.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  const verifiedUser = AuthUser(
    id: 'user-1',
    email: 'student@kku.ac.kr',
    isEmailVerified: true,
  );
  const unverifiedUser = AuthUser(
    id: 'user-2',
    email: 'new@kku.ac.kr',
    isEmailVerified: false,
  );

  group('LoginController', () {
    test('빈 로그인 입력을 검증하고 Firebase 요청을 보내지 않는다', () async {
      final repository = FakeAuthRepository();
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.signIn(email: ' ', password: 'password');

      expect(harness.state.status, LoginStatus.failure);
      expect(harness.state.action, LoginAction.signIn);
      expect(harness.state.message, LoginController.missingCredentialsMessage);
      expect(repository.signInRequests, isEmpty);
    });

    test('입력값을 정리해 로그인하고 인증 완료 상태로 전환한다', () async {
      final repository = FakeAuthRepository(
        signIn: (_, _) async => verifiedUser,
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.signIn(
        email: '  student@kku.ac.kr ',
        password: ' password ',
      );

      expect(harness.states, contains(LoginState.loading(LoginAction.signIn)));
      expect(harness.state.status, LoginStatus.authenticated);
      expect(harness.state.user, verifiedUser);
      expect(repository.signInRequests.single.email, 'student@kku.ac.kr');
      expect(repository.signInRequests.single.password, 'password');
    });

    test('이메일 미인증 사용자는 로그인 화면에 유지할 상태를 만든다', () async {
      final repository = FakeAuthRepository(
        signIn: (_, _) async => unverifiedUser,
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.signIn(
        email: 'new@kku.ac.kr',
        password: 'password',
      );

      expect(harness.state.status, LoginStatus.emailUnverified);
      expect(harness.state.user, unverifiedUser);
      expect(harness.state.message, LoginController.emailUnverifiedMessage);
    });

    test('Firebase 인증 실패를 사용자 오류 상태로 변환한다', () async {
      final repository = FakeAuthRepository(
        signIn: (_, _) async => throw const AuthFailure(
          reason: AuthFailureReason.invalidCredential,
          debugMessage: 'invalid-credential',
        ),
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.signIn(
        email: 'student@kku.ac.kr',
        password: 'wrong-password',
      );

      expect(harness.state.status, LoginStatus.failure);
      expect(harness.state.message, '이메일 또는 비밀번호가 올바르지 않습니다.');
    });

    test('진행 중인 로그인과 겹치는 인증 요청을 건너뛴다', () async {
      final response = Completer<AuthUser>();
      final repository = FakeAuthRepository(signIn: (_, _) => response.future);
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      final signIn = harness.controller.signIn(
        email: 'student@kku.ac.kr',
        password: 'password',
      );
      await harness.container.pump();
      await harness.controller.sendPasswordResetEmail(
        email: 'student@kku.ac.kr',
      );

      expect(harness.state.status, LoginStatus.loading);
      expect(harness.state.action, LoginAction.signIn);
      expect(repository.passwordResetRequests, isEmpty);

      response.complete(verifiedUser);
      await signIn;
      expect(harness.state.status, LoginStatus.authenticated);
    });

    test('비밀번호 재설정 메일을 정리된 이메일로 요청한다', () async {
      final repository = FakeAuthRepository();
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.sendPasswordResetEmail(
        email: '  student@kku.ac.kr ',
      );

      expect(harness.state.status, LoginStatus.passwordResetSent);
      expect(harness.state.message, LoginController.passwordResetSentMessage);
      expect(repository.passwordResetRequests, ['student@kku.ac.kr']);
    });

    test('비밀번호 재설정 실패를 작업에 맞는 메시지로 변환한다', () async {
      final repository = FakeAuthRepository(
        sendPasswordResetEmail: (_) async =>
            throw const AuthFailure(reason: AuthFailureReason.userNotFound),
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.sendPasswordResetEmail(
        email: 'unknown@kku.ac.kr',
      );

      expect(harness.state.status, LoginStatus.failure);
      expect(harness.state.action, LoginAction.passwordReset);
      expect(harness.state.message, '등록되지 않은 이메일입니다.');
    });
  });
}

_LoginHarness _createHarness(FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  final states = <LoginState>[];
  final subscription = container.listen(
    loginControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _LoginHarness(
    container: container,
    subscription: subscription,
    states: states,
  );
}

final class _LoginHarness {
  const _LoginHarness({
    required this.container,
    required this.subscription,
    required this.states,
  });

  final ProviderContainer container;
  final ProviderSubscription<LoginState> subscription;
  final List<LoginState> states;

  LoginState get state => container.read(loginControllerProvider);

  LoginController get controller {
    return container.read(loginControllerProvider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}
