import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/application/auth_session_controller.dart';
import 'package:kku_ottae/features/auth/application/auth_session_state.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('AuthSessionController', () {
    test('Firebase 로그아웃 완료 후 signedOut 상태가 된다', () async {
      final repository = FakeAuthRepository(signOut: () async {});
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.signOut();

      expect(harness.states, contains(const AuthSessionState.signingOut()));
      expect(harness.state.status, AuthSessionStatus.signedOut);
      expect(repository.signOutRequestCount, 1);
    });

    test('로그아웃 실패 상태에서 다시 시도하면 정상 종료한다', () async {
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
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.signOut();

      expect(harness.state.status, AuthSessionStatus.failure);
      expect(harness.state.message, '네트워크 연결을 확인해주세요.');

      await harness.controller.retry();

      expect(harness.state.status, AuthSessionStatus.signedOut);
      expect(repository.signOutRequestCount, 2);
    });

    test('진행 중인 로그아웃과 겹치는 요청을 건너뛴다', () async {
      final response = Completer<void>();
      final repository = FakeAuthRepository(signOut: () => response.future);
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      final firstRequest = harness.controller.signOut();
      await harness.container.pump();
      await harness.controller.signOut();

      expect(harness.state.status, AuthSessionStatus.signingOut);
      expect(repository.signOutRequestCount, 1);

      response.complete();
      await firstRequest;
      expect(harness.state.status, AuthSessionStatus.signedOut);
    });

    test('실패 상태가 아니면 다시 시도하지 않는다', () async {
      final repository = FakeAuthRepository(signOut: () async {});
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.retry();

      expect(harness.state.status, AuthSessionStatus.idle);
      expect(repository.signOutRequestCount, 0);
    });
  });
}

_AuthSessionHarness _createHarness(FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  final states = <AuthSessionState>[];
  final subscription = container.listen(
    authSessionControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _AuthSessionHarness(
    container: container,
    subscription: subscription,
    states: states,
  );
}

final class _AuthSessionHarness {
  const _AuthSessionHarness({
    required this.container,
    required this.subscription,
    required this.states,
  });

  final ProviderContainer container;
  final ProviderSubscription<AuthSessionState> subscription;
  final List<AuthSessionState> states;

  AuthSessionState get state => container.read(authSessionControllerProvider);

  AuthSessionController get controller {
    return container.read(authSessionControllerProvider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}
