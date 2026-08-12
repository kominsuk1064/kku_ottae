enum AuthFailureReason {
  invalidEmail,
  userDisabled,
  userNotFound,
  wrongPassword,
  invalidCredential,
  tooManyRequests,
  networkUnavailable,
  unknown,
}

final class AuthFailure implements Exception {
  const AuthFailure({required this.reason, this.debugMessage});

  final AuthFailureReason reason;
  final String? debugMessage;

  @override
  String toString() {
    final details = debugMessage;
    return details == null
        ? 'AuthFailure(${reason.name})'
        : 'AuthFailure(${reason.name}): $details';
  }
}
