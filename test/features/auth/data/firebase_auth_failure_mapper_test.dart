import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/data/firebase_auth_failure_mapper.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';

void main() {
  group('mapFirebaseAuthFailure', () {
    const cases = <String, AuthFailureReason>{
      'invalid-email': AuthFailureReason.invalidEmail,
      'email-already-in-use': AuthFailureReason.emailAlreadyInUse,
      'weak-password': AuthFailureReason.weakPassword,
      'operation-not-allowed': AuthFailureReason.operationNotAllowed,
      'user-disabled': AuthFailureReason.userDisabled,
      'user-not-found': AuthFailureReason.userNotFound,
      'wrong-password': AuthFailureReason.wrongPassword,
      'invalid-credential': AuthFailureReason.invalidCredential,
      'too-many-requests': AuthFailureReason.tooManyRequests,
      'network-request-failed': AuthFailureReason.networkUnavailable,
      'requires-recent-login': AuthFailureReason.requiresRecentLogin,
      'not-mapped': AuthFailureReason.unknown,
    };

    for (final entry in cases.entries) {
      test('${entry.key} 코드를 ${entry.value.name} 실패로 변환한다', () {
        final failure = mapFirebaseAuthFailure(
          FirebaseAuthException(code: entry.key, message: 'firebase message'),
        );

        expect(failure.reason, entry.value);
        expect(failure.debugMessage, contains(entry.key));
      });
    }
  });
}
