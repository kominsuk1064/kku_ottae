import '../domain/auth_user.dart';

enum SignupAction { requestVerification, checkVerification, saveProfile }

enum SignupStatus {
  idle,
  loading,
  verificationEmailSent,
  emailNotVerified,
  emailVerified,
  completed,
  failure,
}

final class SignupState {
  const SignupState._({
    required this.status,
    required this.action,
    required this.user,
    required this.message,
  });

  const SignupState.idle()
    : this._(
        status: SignupStatus.idle,
        action: null,
        user: null,
        message: null,
      );

  factory SignupState.loading({required SignupAction action, AuthUser? user}) {
    return SignupState._(
      status: SignupStatus.loading,
      action: action,
      user: user,
      message: null,
    );
  }

  factory SignupState.verificationEmailSent({
    required AuthUser user,
    required String message,
  }) {
    return SignupState._(
      status: SignupStatus.verificationEmailSent,
      action: SignupAction.requestVerification,
      user: user,
      message: message,
    );
  }

  factory SignupState.emailNotVerified({
    required AuthUser user,
    required String message,
  }) {
    return SignupState._(
      status: SignupStatus.emailNotVerified,
      action: SignupAction.checkVerification,
      user: user,
      message: message,
    );
  }

  factory SignupState.emailVerified({
    required AuthUser user,
    required String message,
  }) {
    return SignupState._(
      status: SignupStatus.emailVerified,
      action: SignupAction.checkVerification,
      user: user,
      message: message,
    );
  }

  factory SignupState.completed({
    required AuthUser user,
    required String message,
  }) {
    return SignupState._(
      status: SignupStatus.completed,
      action: SignupAction.saveProfile,
      user: user,
      message: message,
    );
  }

  factory SignupState.failure({
    required SignupAction action,
    required String message,
    AuthUser? user,
  }) {
    return SignupState._(
      status: SignupStatus.failure,
      action: action,
      user: user,
      message: message,
    );
  }

  final SignupStatus status;
  final SignupAction? action;
  final AuthUser? user;
  final String? message;

  bool get isLoading => status == SignupStatus.loading;

  bool get hasAccount => user != null;

  bool get isEmailVerified => user?.isEmailVerified ?? false;

  bool get isRequestingVerification {
    return isLoading && action == SignupAction.requestVerification;
  }

  bool get isCheckingVerification {
    return isLoading && action == SignupAction.checkVerification;
  }

  bool get isSavingProfile {
    return isLoading && action == SignupAction.saveProfile;
  }

  bool get canCheckVerification {
    return hasAccount && !isEmailVerified && !isLoading;
  }

  bool get canCompleteSignup => isEmailVerified && !isLoading;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SignupState &&
            status == other.status &&
            action == other.action &&
            user == other.user &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(status, action, user, message);
}
