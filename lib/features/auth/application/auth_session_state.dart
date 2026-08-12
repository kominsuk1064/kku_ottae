enum AuthSessionStatus { idle, signingOut, signedOut, failure }

final class AuthSessionState {
  const AuthSessionState._({required this.status, required this.message});

  const AuthSessionState.idle()
    : this._(status: AuthSessionStatus.idle, message: null);

  const AuthSessionState.signingOut()
    : this._(status: AuthSessionStatus.signingOut, message: null);

  const AuthSessionState.signedOut()
    : this._(status: AuthSessionStatus.signedOut, message: null);

  const AuthSessionState.failure({required String message})
    : this._(status: AuthSessionStatus.failure, message: message);

  final AuthSessionStatus status;
  final String? message;

  bool get isSigningOut => status == AuthSessionStatus.signingOut;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSessionState &&
            status == other.status &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(status, message);
}
