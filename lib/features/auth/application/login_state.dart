import '../domain/auth_user.dart';

enum LoginAction { signIn, passwordReset }

enum LoginStatus {
  idle,
  loading,
  authenticated,
  emailUnverified,
  passwordResetSent,
  failure,
}

final class LoginState {
  const LoginState._({
    required this.status,
    required this.action,
    required this.user,
    required this.message,
  });

  const LoginState.idle()
    : this._(status: LoginStatus.idle, action: null, user: null, message: null);

  factory LoginState.loading(LoginAction action) {
    return LoginState._(
      status: LoginStatus.loading,
      action: action,
      user: null,
      message: null,
    );
  }

  factory LoginState.authenticated({
    required AuthUser user,
    required String message,
  }) {
    return LoginState._(
      status: LoginStatus.authenticated,
      action: LoginAction.signIn,
      user: user,
      message: message,
    );
  }

  factory LoginState.emailUnverified({
    required AuthUser user,
    required String message,
  }) {
    return LoginState._(
      status: LoginStatus.emailUnverified,
      action: LoginAction.signIn,
      user: user,
      message: message,
    );
  }

  factory LoginState.passwordResetSent({required String message}) {
    return LoginState._(
      status: LoginStatus.passwordResetSent,
      action: LoginAction.passwordReset,
      user: null,
      message: message,
    );
  }

  factory LoginState.failure({
    required LoginAction action,
    required String message,
  }) {
    return LoginState._(
      status: LoginStatus.failure,
      action: action,
      user: null,
      message: message,
    );
  }

  final LoginStatus status;
  final LoginAction? action;
  final AuthUser? user;
  final String? message;

  bool get isLoading => status == LoginStatus.loading;

  bool get isSigningIn => isLoading && action == LoginAction.signIn;

  bool get isResettingPassword {
    return isLoading && action == LoginAction.passwordReset;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LoginState &&
            status == other.status &&
            action == other.action &&
            user == other.user &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(status, action, user, message);
}
