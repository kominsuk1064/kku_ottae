enum UserProfileFailureReason {
  permissionDenied,
  unauthenticated,
  temporarilyUnavailable,
  unknown,
}

final class UserProfileFailure implements Exception {
  const UserProfileFailure({required this.reason, this.debugMessage});

  final UserProfileFailureReason reason;
  final String? debugMessage;

  @override
  String toString() {
    final details = debugMessage;
    return details == null
        ? 'UserProfileFailure(${reason.name})'
        : 'UserProfileFailure(${reason.name}): $details';
  }
}
