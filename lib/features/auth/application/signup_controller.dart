import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/profile_providers.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/domain/user_profile_failure.dart';
import '../../profile/domain/user_profile_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_providers.dart';
import 'signup_state.dart';

final signupControllerProvider =
    NotifierProvider.autoDispose<SignupController, SignupState>(
      SignupController.new,
    );

final class SignupController extends Notifier<SignupState> {
  static const missingAccountFieldsMessage = '이메일과 비밀번호를 모두 입력해주세요.';
  static const invalidSchoolEmailMessage = '반드시 @kku.ac.kr 이메일을 입력해주세요.';
  static const passwordMismatchMessage = '비밀번호가 일치하지 않습니다.';
  static const verificationEmailSentMessage = '인증 메일을 보냈습니다.';
  static const emailVerifiedMessage = '이메일 인증이 완료되었습니다.';
  static const emailNotVerifiedMessage = '이메일 인증이 아직 완료되지 않았습니다.';
  static const missingProfileFieldsMessage = '이름과 학번을 모두 입력해주세요.';
  static const signupCompletedMessage = '회원가입이 완료되었습니다.';

  static final _schoolEmailPattern = RegExp(
    r'^[\w\.-]+@kku\.ac\.kr$',
    caseSensitive: false,
  );

  late final AuthRepository _authRepository;
  late final UserProfileRepository _profileRepository;
  AuthUser? _registeredUser;
  bool _operationInFlight = false;
  bool _disposed = false;

  @override
  SignupState build() {
    _authRepository = ref.read(authRepositoryProvider);
    _profileRepository = ref.read(userProfileRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    return const SignupState.idle();
  }

  Future<void> requestEmailVerification({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (_disposed || _operationInFlight) {
      return;
    }

    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();
    final normalizedConfirmPassword = confirmPassword.trim();
    final validationMessage = _registeredUser == null
        ? _validateAccountInput(
            email: normalizedEmail,
            password: normalizedPassword,
            confirmPassword: normalizedConfirmPassword,
          )
        : _validateExistingAccountEmail(normalizedEmail);
    if (validationMessage != null) {
      state = SignupState.failure(
        action: SignupAction.requestVerification,
        user: _registeredUser,
        message: validationMessage,
      );
      return;
    }

    _operationInFlight = true;
    state = SignupState.loading(
      action: SignupAction.requestVerification,
      user: _registeredUser,
    );
    try {
      if (_registeredUser == null) {
        final user = await _authRepository.createUser(
          email: normalizedEmail,
          password: normalizedPassword,
        );
        if (_disposed) {
          return;
        }
        _registeredUser = user;
        state = SignupState.loading(
          action: SignupAction.requestVerification,
          user: user,
        );
      }

      await _authRepository.sendEmailVerification();
      if (_disposed) {
        return;
      }
      state = SignupState.verificationEmailSent(
        user: _registeredUser!,
        message: verificationEmailSentMessage,
      );
    } on AuthFailure catch (error, stackTrace) {
      _reportAuthFailure(
        action: SignupAction.requestVerification,
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(
        action: SignupAction.requestVerification,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> checkEmailVerification() async {
    if (_disposed || _operationInFlight) {
      return;
    }
    if (_registeredUser == null) {
      state = SignupState.failure(
        action: SignupAction.checkVerification,
        message: '인증할 계정 정보가 없습니다. 인증 요청을 먼저 진행해주세요.',
      );
      return;
    }

    _operationInFlight = true;
    state = SignupState.loading(
      action: SignupAction.checkVerification,
      user: _registeredUser,
    );
    try {
      final user = await _authRepository.reloadCurrentUser();
      if (_disposed) {
        return;
      }
      _registeredUser = user;
      state = user.isEmailVerified
          ? SignupState.emailVerified(user: user, message: emailVerifiedMessage)
          : SignupState.emailNotVerified(
              user: user,
              message: emailNotVerifiedMessage,
            );
    } on AuthFailure catch (error, stackTrace) {
      _reportAuthFailure(
        action: SignupAction.checkVerification,
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(
        action: SignupAction.checkVerification,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> completeSignup({
    required String name,
    required String studentId,
  }) async {
    if (_disposed || _operationInFlight) {
      return;
    }
    final user = _registeredUser;
    if (user == null || !user.isEmailVerified) {
      state = SignupState.failure(
        action: SignupAction.saveProfile,
        user: user,
        message: '이메일 인증을 완료해주세요.',
      );
      return;
    }

    final normalizedName = name.trim();
    final normalizedStudentId = studentId.trim();
    if (normalizedName.isEmpty || normalizedStudentId.isEmpty) {
      state = SignupState.failure(
        action: SignupAction.saveProfile,
        user: user,
        message: missingProfileFieldsMessage,
      );
      return;
    }

    _operationInFlight = true;
    state = SignupState.loading(action: SignupAction.saveProfile, user: user);
    try {
      await _profileRepository.saveProfile(
        UserProfile(
          userId: user.id,
          name: normalizedName,
          studentId: normalizedStudentId,
          email: user.email,
        ),
      );
      if (_disposed) {
        return;
      }
      state = SignupState.completed(
        user: user,
        message: signupCompletedMessage,
      );
    } on UserProfileFailure catch (error, stackTrace) {
      _reportProfileFailure(error: error, stackTrace: stackTrace);
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(
        action: SignupAction.saveProfile,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationInFlight = false;
    }
  }

  String? _validateAccountInput({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return missingAccountFieldsMessage;
    }
    if (!_schoolEmailPattern.hasMatch(email)) {
      return invalidSchoolEmailMessage;
    }
    if (password != confirmPassword) {
      return passwordMismatchMessage;
    }
    return null;
  }

  String? _validateExistingAccountEmail(String email) {
    final registeredEmail = _registeredUser?.email;
    if (email.isEmpty ||
        registeredEmail == null ||
        email.toLowerCase() != registeredEmail.toLowerCase()) {
      return '계정을 생성한 이메일은 변경할 수 없습니다.';
    }
    return null;
  }

  void _reportAuthFailure({
    required SignupAction action,
    required AuthFailure error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      _operationLabel(action),
      name: 'kku_ottae.signup',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = SignupState.failure(
      action: action,
      user: _registeredUser,
      message: _authFailureMessage(action, error.reason),
    );
  }

  void _reportProfileFailure({
    required UserProfileFailure error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      '회원 프로필 저장 실패',
      name: 'kku_ottae.signup',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = SignupState.failure(
      action: SignupAction.saveProfile,
      user: _registeredUser,
      message: switch (error.reason) {
        UserProfileFailureReason.permissionDenied ||
        UserProfileFailureReason.unauthenticated => '회원정보를 저장할 권한이 없습니다.',
        UserProfileFailureReason.temporarilyUnavailable =>
          '회원정보 저장 서버에 연결할 수 없습니다. 다시 시도해주세요.',
        UserProfileFailureReason.unknown => '회원정보를 저장하지 못했습니다. 다시 시도해주세요.',
      },
    );
  }

  void _reportUnexpectedFailure({
    required SignupAction action,
    required Object error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      '예상하지 못한 ${_operationLabel(action)}',
      name: 'kku_ottae.signup',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = SignupState.failure(
      action: action,
      user: _registeredUser,
      message: action == SignupAction.saveProfile
          ? '회원정보를 저장하지 못했습니다. 다시 시도해주세요.'
          : '인증 처리 중 오류가 발생했습니다. 다시 시도해주세요.',
    );
  }

  String _authFailureMessage(SignupAction action, AuthFailureReason reason) {
    if (action == SignupAction.checkVerification) {
      return switch (reason) {
        AuthFailureReason.noCurrentUser => '인증할 계정 정보가 없습니다. 인증 요청을 다시 진행해주세요.',
        AuthFailureReason.tooManyRequests => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
        AuthFailureReason.networkUnavailable => '네트워크 연결을 확인해주세요.',
        _ => '이메일 인증 상태를 확인하지 못했습니다. 다시 시도해주세요.',
      };
    }

    return switch (reason) {
      AuthFailureReason.invalidEmail => '이메일 형식을 확인해주세요.',
      AuthFailureReason.emailAlreadyInUse => '이미 가입된 이메일입니다.',
      AuthFailureReason.weakPassword => '더 안전한 비밀번호를 입력해주세요.',
      AuthFailureReason.operationNotAllowed => '현재 이메일 회원가입을 사용할 수 없습니다.',
      AuthFailureReason.tooManyRequests => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
      AuthFailureReason.networkUnavailable => '네트워크 연결을 확인해주세요.',
      AuthFailureReason.noCurrentUser => '인증할 계정 정보가 없습니다. 다시 시도해주세요.',
      AuthFailureReason.requiresRecentLogin ||
      AuthFailureReason.userDisabled ||
      AuthFailureReason.userNotFound ||
      AuthFailureReason.wrongPassword ||
      AuthFailureReason.invalidCredential ||
      AuthFailureReason.unknown => '인증 메일을 보내지 못했습니다. 다시 시도해주세요.',
    };
  }

  String _operationLabel(SignupAction action) {
    return switch (action) {
      SignupAction.requestVerification => '인증 메일 요청 실패',
      SignupAction.checkVerification => '이메일 인증 확인 실패',
      SignupAction.saveProfile => '회원 프로필 저장 실패',
    };
  }
}
