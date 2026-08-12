import 'package:firebase_core/firebase_core.dart';

import '../domain/feedback_failure.dart';

FeedbackFailure mapFirestoreFeedbackFailure(FirebaseException exception) {
  final reason = switch (exception.code) {
    'permission-denied' => FeedbackFailureReason.permissionDenied,
    'unauthenticated' => FeedbackFailureReason.unauthenticated,
    'unavailable' ||
    'deadline-exceeded' => FeedbackFailureReason.temporarilyUnavailable,
    _ => FeedbackFailureReason.unknown,
  };

  return FeedbackFailure(
    reason: reason,
    debugMessage: '${exception.code}: ${exception.message ?? 'no message'}',
  );
}
