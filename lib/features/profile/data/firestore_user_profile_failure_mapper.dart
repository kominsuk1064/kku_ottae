import 'package:firebase_core/firebase_core.dart';

import '../domain/user_profile_failure.dart';

UserProfileFailure mapFirestoreUserProfileFailure(FirebaseException exception) {
  final reason = switch (exception.code) {
    'permission-denied' => UserProfileFailureReason.permissionDenied,
    'unauthenticated' => UserProfileFailureReason.unauthenticated,
    'unavailable' ||
    'deadline-exceeded' => UserProfileFailureReason.temporarilyUnavailable,
    _ => UserProfileFailureReason.unknown,
  };

  return UserProfileFailure(
    reason: reason,
    debugMessage: '${exception.code}: ${exception.message ?? 'no message'}',
  );
}
