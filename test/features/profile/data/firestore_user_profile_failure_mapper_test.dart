import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/profile/data/firestore_user_profile_failure_mapper.dart';
import 'package:kku_ottae/features/profile/domain/user_profile_failure.dart';

void main() {
  group('mapFirestoreUserProfileFailure', () {
    const cases = <String, UserProfileFailureReason>{
      'permission-denied': UserProfileFailureReason.permissionDenied,
      'unauthenticated': UserProfileFailureReason.unauthenticated,
      'unavailable': UserProfileFailureReason.temporarilyUnavailable,
      'deadline-exceeded': UserProfileFailureReason.temporarilyUnavailable,
      'not-mapped': UserProfileFailureReason.unknown,
    };

    for (final entry in cases.entries) {
      test('${entry.key} 코드를 ${entry.value.name} 실패로 변환한다', () {
        final failure = mapFirestoreUserProfileFailure(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: entry.key,
            message: 'firestore message',
          ),
        );

        expect(failure.reason, entry.value);
        expect(failure.debugMessage, contains(entry.key));
      });
    }
  });
}
