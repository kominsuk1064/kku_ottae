import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/application/change_password_controller.dart';
import 'package:kku_ottae/features/auth/application/change_password_state.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('ChangePasswordController', () {
    final invalidInputs =
        <
          ({
            String description,
            String currentPassword,
            String newPassword,
            String confirmPassword,
            String message,
          })
        >[
          (
            description: '빈 입력',
            currentPassword: '',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
            message: ChangePasswordController.missingFieldsMessage,
          ),
          (
            description: '불일치하는 새 비밀번호',
            currentPassword: 'current-password',
            newPassword: 'new-password',
            confirmPassword: 'different-password',
            message: ChangePasswordController.passwordMismatchMessage,
          ),
          (
            description: '6자 미만 새 비밀번호',
            currentPassword: 'current-password',
            newPassword: 'short',
            confirmPassword: 'short',
            message: ChangePasswordController.passwordTooShortMessage,
          ),
        ];

    for (final input in invalidInputs) {
      test('${input.description}을 검증하고 Repository를 호출하지 않는다', () async {
        final repository = FakeAuthRepository();
        final harness = _createHarness(repository);
        addTearDown(harness.dispose);

        await harness.controller.changePassword(
          currentPassword: input.currentPassword,
          newPassword: input.newPassword,
          confirmPassword: input.confirmPassword,
        );

        expect(harness.state.status, ChangePasswordStatus.failure);
        expect(harness.state.message, input.message);
        expect(repository.changePasswordRequests, isEmpty);
      });
    }

    test('정리된 비밀번호로 재인증하고 변경 완료 상태가 된다', () async {
      final repository = FakeAuthRepository(changePassword: (_, _) async {});
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await harness.controller.changePassword(
        currentPassword: ' current-password ',
        newPassword: ' new-password ',
        confirmPassword: ' new-password ',
      );

      expect(harness.states, contains(const ChangePasswordState.loading()));
      expect(harness.state.status, ChangePasswordStatus.success);
      expect(harness.state.message, ChangePasswordController.successMessage);
      expect(
        repository.changePasswordRequests.single.currentPassword,
        'current-password',
      );
      expect(
        repository.changePasswordRequests.single.newPassword,
        'new-password',
      );
    });

    test('현재 비밀번호 오류를 사용자 메시지로 변환한다', () async {
      final repository = FakeAuthRepository(
        changePassword: (_, _) async => throw const AuthFailure(
          reason: AuthFailureReason.invalidCredential,
          debugMessage: 'firebase internal details',
        ),
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await _changePassword(harness.controller);

      expect(harness.state.status, ChangePasswordStatus.failure);
      expect(harness.state.message, '현재 비밀번호가 올바르지 않습니다.');
      expect(harness.state.message, isNot(contains('firebase')));
    });

    test('보안상 재로그인이 필요한 오류를 안내한다', () async {
      final repository = FakeAuthRepository(
        changePassword: (_, _) async => throw const AuthFailure(
          reason: AuthFailureReason.requiresRecentLogin,
        ),
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      await _changePassword(harness.controller);

      expect(harness.state.status, ChangePasswordStatus.failure);
      expect(harness.state.message, '보안을 위해 다시 로그인한 후 시도해주세요.');
    });

    test('진행 중인 비밀번호 변경과 겹치는 요청을 건너뛴다', () async {
      final response = Completer<void>();
      final repository = FakeAuthRepository(
        changePassword: (_, _) => response.future,
      );
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);

      final firstRequest = _changePassword(harness.controller);
      await harness.container.pump();
      await _changePassword(harness.controller);

      expect(harness.state.status, ChangePasswordStatus.loading);
      expect(repository.changePasswordRequests.length, 1);

      response.complete();
      await firstRequest;
      expect(harness.state.status, ChangePasswordStatus.success);
    });
  });
}

Future<void> _changePassword(ChangePasswordController controller) {
  return controller.changePassword(
    currentPassword: 'current-password',
    newPassword: 'new-password',
    confirmPassword: 'new-password',
  );
}

_ChangePasswordHarness _createHarness(FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  final states = <ChangePasswordState>[];
  final subscription = container.listen(
    changePasswordControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _ChangePasswordHarness(
    container: container,
    subscription: subscription,
    states: states,
  );
}

final class _ChangePasswordHarness {
  const _ChangePasswordHarness({
    required this.container,
    required this.subscription,
    required this.states,
  });

  final ProviderContainer container;
  final ProviderSubscription<ChangePasswordState> subscription;
  final List<ChangePasswordState> states;

  ChangePasswordState get state {
    return container.read(changePasswordControllerProvider);
  }

  ChangePasswordController get controller {
    return container.read(changePasswordControllerProvider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}
