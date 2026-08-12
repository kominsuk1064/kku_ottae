enum FeedbackFailureReason {
  permissionDenied,
  unauthenticated,
  temporarilyUnavailable,
  unknown,
}

final class FeedbackFailure implements Exception {
  const FeedbackFailure({required this.reason, this.debugMessage});

  final FeedbackFailureReason reason;
  final String? debugMessage;

  @override
  String toString() {
    final details = debugMessage;
    return details == null
        ? 'FeedbackFailure(${reason.name})'
        : 'FeedbackFailure(${reason.name}): $details';
  }
}
