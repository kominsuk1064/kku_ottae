import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_failure.dart';

AuthFailure mapFirebaseAuthFailure(FirebaseAuthException exception) {
  final reason = switch (exception.code) {
    'invalid-email' => AuthFailureReason.invalidEmail,
    'email-already-in-use' => AuthFailureReason.emailAlreadyInUse,
    'weak-password' => AuthFailureReason.weakPassword,
    'operation-not-allowed' => AuthFailureReason.operationNotAllowed,
    'user-disabled' => AuthFailureReason.userDisabled,
    'user-not-found' => AuthFailureReason.userNotFound,
    'wrong-password' => AuthFailureReason.wrongPassword,
    'invalid-credential' => AuthFailureReason.invalidCredential,
    'too-many-requests' => AuthFailureReason.tooManyRequests,
    'network-request-failed' => AuthFailureReason.networkUnavailable,
    'requires-recent-login' => AuthFailureReason.requiresRecentLogin,
    _ => AuthFailureReason.unknown,
  };

  return AuthFailure(
    reason: reason,
    debugMessage: '${exception.code}: ${exception.message ?? 'no message'}',
  );
}
