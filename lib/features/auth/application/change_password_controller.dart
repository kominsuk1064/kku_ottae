import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import 'auth_providers.dart';
import 'change_password_state.dart';

final changePasswordControllerProvider =
    NotifierProvider.autoDispose<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );

final class ChangePasswordController extends Notifier<ChangePasswordState> {
  static const missingFieldsMessage = '모든 필드를 입력해주세요.';
  static const passwordMismatchMessage = '새 비밀번호가 일치하지 않습니다.';
  static const passwordTooShortMessage = '비밀번호는 최소 6자 이상이어야 합니다.';
  static const successMessage = '비밀번호가 성공적으로 변경되었습니다.';

  late final AuthRepository _repository;
  bool _operationInFlight = false;
  bool _disposed = false;

  @override
  ChangePasswordState build() {
    _repository = ref.read(authRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    return const ChangePasswordState.idle();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_disposed || _operationInFlight) {
      return;
    }

    final normalizedCurrentPassword = currentPassword.trim();
    final normalizedNewPassword = newPassword.trim();
    final normalizedConfirmPassword = confirmPassword.trim();
    final validationMessage = _validate(
      currentPassword: normalizedCurrentPassword,
      newPassword: normalizedNewPassword,
      confirmPassword: normalizedConfirmPassword,
    );
    if (validationMessage != null) {
      state = ChangePasswordState.failure(message: validationMessage);
      return;
    }

    _operationInFlight = true;
    state = const ChangePasswordState.loading();
    try {
      await _repository.changePassword(
        currentPassword: normalizedCurrentPassword,
        newPassword: normalizedNewPassword,
      );
      if (_disposed) {
        return;
      }
      state = const ChangePasswordState.success(message: successMessage);
    } on AuthFailure catch (error, stackTrace) {
      _reportAuthFailure(error, stackTrace);
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(error, stackTrace);
    } finally {
      _operationInFlight = false;
    }
  }

  String? _validate({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      return missingFieldsMessage;
    }
    if (newPassword != confirmPassword) {
      return passwordMismatchMessage;
    }
    if (newPassword.length < 6) {
      return passwordTooShortMessage;
    }
    return null;
  }

  void _reportAuthFailure(AuthFailure error, StackTrace stackTrace) {
    developer.log(
      '비밀번호 변경 실패',
      name: 'kku_ottae.auth',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = ChangePasswordState.failure(message: _failureMessage(error.reason));
  }

  void _reportUnexpectedFailure(Object error, StackTrace stackTrace) {
    developer.log(
      '예상하지 못한 비밀번호 변경 오류',
      name: 'kku_ottae.auth',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = const ChangePasswordState.failure(
      message: '비밀번호를 변경하지 못했습니다. 다시 시도해주세요.',
    );
  }

  String _failureMessage(AuthFailureReason reason) {
    return switch (reason) {
      AuthFailureReason.wrongPassword ||
      AuthFailureReason.invalidCredential => '현재 비밀번호가 올바르지 않습니다.',
      AuthFailureReason.weakPassword => '새 비밀번호가 보안 기준을 충족하지 않습니다.',
      AuthFailureReason.requiresRecentLogin => '보안을 위해 다시 로그인한 후 시도해주세요.',
      AuthFailureReason.noCurrentUser ||
      AuthFailureReason.userNotFound => '로그인이 필요합니다.',
      AuthFailureReason.userDisabled => '사용이 중지된 계정입니다.',
      AuthFailureReason.tooManyRequests => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
      AuthFailureReason.networkUnavailable => '네트워크 연결을 확인해주세요.',
      AuthFailureReason.invalidEmail ||
      AuthFailureReason.emailAlreadyInUse ||
      AuthFailureReason.operationNotAllowed ||
      AuthFailureReason.unknown => '비밀번호를 변경하지 못했습니다. 다시 시도해주세요.',
    };
  }
}
