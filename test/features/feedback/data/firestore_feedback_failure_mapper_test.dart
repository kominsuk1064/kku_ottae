import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/feedback/data/firestore_feedback_failure_mapper.dart';
import 'package:kku_ottae/features/feedback/domain/feedback_failure.dart';

void main() {
  group('mapFirestoreFeedbackFailure', () {
    const cases = <String, FeedbackFailureReason>{
      'permission-denied': FeedbackFailureReason.permissionDenied,
      'unauthenticated': FeedbackFailureReason.unauthenticated,
      'unavailable': FeedbackFailureReason.temporarilyUnavailable,
      'deadline-exceeded': FeedbackFailureReason.temporarilyUnavailable,
      'not-mapped': FeedbackFailureReason.unknown,
    };

    for (final entry in cases.entries) {
      test('${entry.key} 코드를 ${entry.value.name} 실패로 변환한다', () {
        final failure = mapFirestoreFeedbackFailure(
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
