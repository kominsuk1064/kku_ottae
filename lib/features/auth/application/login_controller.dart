import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import 'auth_providers.dart';
import 'login_state.dart';

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );

final class LoginController extends Notifier<LoginState> {
  static const missingCredentialsMessage = '이메일과 비밀번호를 모두 입력해주세요.';
  static const missingEmailMessage = '이메일을 입력해주세요.';
  static const loginSuccessMessage = '로그인에 성공했습니다.';
  static const emailUnverifiedMessage = '이메일 인증이 완료되지 않았습니다.';
  static const passwordResetSentMessage = '비밀번호 재설정 메일을 보냈습니다.';

  late final AuthRepository _repository;
  bool _operationInFlight = false;
  bool _disposed = false;

  @override
  LoginState build() {
    _repository = ref.read(authRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    return const LoginState.idle();
  }

  Future<void> signIn({required String email, required String password}) async {
    if (_disposed || _operationInFlight) {
      return;
    }

    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();
    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      state = LoginState.failure(
        action: LoginAction.signIn,
        message: missingCredentialsMessage,
      );
      return;
    }

    _operationInFlight = true;
    state = LoginState.loading(LoginAction.signIn);
    try {
      final user = await _repository.signIn(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      if (_disposed) {
        return;
      }

      state = user.isEmailVerified
          ? LoginState.authenticated(user: user, message: loginSuccessMessage)
          : LoginState.emailUnverified(
              user: user,
              message: emailUnverifiedMessage,
            );
    } on AuthFailure catch (error, stackTrace) {
      _reportFailure(
        action: LoginAction.signIn,
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(
        action: LoginAction.signIn,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (_disposed || _operationInFlight) {
      return;
    }

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      state = LoginState.failure(
        action: LoginAction.passwordReset,
        message: missingEmailMessage,
      );
      return;
    }

    _operationInFlight = true;
    state = LoginState.loading(LoginAction.passwordReset);
    try {
      await _repository.sendPasswordResetEmail(email: normalizedEmail);
      if (_disposed) {
        return;
      }
      state = LoginState.passwordResetSent(message: passwordResetSentMessage);
    } on AuthFailure catch (error, stackTrace) {
      _reportFailure(
        action: LoginAction.passwordReset,
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(
        action: LoginAction.passwordReset,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationInFlight = false;
    }
  }

  void _reportFailure({
    required LoginAction action,
    required AuthFailure error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      action == LoginAction.signIn ? '로그인 실패' : '비밀번호 재설정 메일 전송 실패',
      name: 'kku_ottae.auth',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = LoginState.failure(
      action: action,
      message: _failureMessage(action, error.reason),
    );
  }

  void _reportUnexpectedFailure({
    required LoginAction action,
    required Object error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      action == LoginAction.signIn ? '예상하지 못한 로그인 오류' : '예상하지 못한 비밀번호 재설정 오류',
      name: 'kku_ottae.auth',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = LoginState.failure(
      action: action,
      message: action == LoginAction.signIn
          ? '로그인 중 오류가 발생했습니다.'
          : '메일 전송 중 오류가 발생했습니다.',
    );
  }

  String _failureMessage(LoginAction action, AuthFailureReason reason) {
    if (action == LoginAction.passwordReset) {
      return switch (reason) {
        AuthFailureReason.invalidEmail => '이메일 형식을 확인해주세요.',
        AuthFailureReason.userNotFound => '등록되지 않은 이메일입니다.',
        AuthFailureReason.userDisabled => '사용이 중지된 계정입니다.',
        AuthFailureReason.tooManyRequests => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
        AuthFailureReason.networkUnavailable => '네트워크 연결을 확인해주세요.',
        AuthFailureReason.requiresRecentLogin ||
        AuthFailureReason.emailAlreadyInUse ||
        AuthFailureReason.weakPassword ||
        AuthFailureReason.operationNotAllowed ||
        AuthFailureReason.noCurrentUser ||
        AuthFailureReason.wrongPassword ||
        AuthFailureReason.invalidCredential ||
        AuthFailureReason.unknown => '메일 전송 중 오류가 발생했습니다.',
      };
    }

    return switch (reason) {
      AuthFailureReason.invalidEmail => '이메일 형식을 확인해주세요.',
      AuthFailureReason.userDisabled => '사용이 중지된 계정입니다.',
      AuthFailureReason.userNotFound => '존재하지 않는 이메일입니다.',
      AuthFailureReason.wrongPassword => '비밀번호가 틀렸습니다.',
      AuthFailureReason.invalidCredential => '이메일 또는 비밀번호가 올바르지 않습니다.',
      AuthFailureReason.tooManyRequests => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
      AuthFailureReason.networkUnavailable => '네트워크 연결을 확인해주세요.',
      AuthFailureReason.requiresRecentLogin ||
      AuthFailureReason.emailAlreadyInUse ||
      AuthFailureReason.weakPassword ||
      AuthFailureReason.operationNotAllowed ||
      AuthFailureReason.noCurrentUser ||
      AuthFailureReason.unknown => '로그인 중 오류가 발생했습니다.',
    };
  }
}
