enum FeedbackSubmissionStatus { idle, submitting, success, failure }

final class FeedbackSubmissionState {
  const FeedbackSubmissionState._({
    required this.status,
    required this.rating,
    required this.message,
  });

  const FeedbackSubmissionState.idle({int rating = 5})
    : this._(
        status: FeedbackSubmissionStatus.idle,
        rating: rating,
        message: null,
      );

  const FeedbackSubmissionState.submitting({required int rating})
    : this._(
        status: FeedbackSubmissionStatus.submitting,
        rating: rating,
        message: null,
      );

  const FeedbackSubmissionState.success({
    required int rating,
    required String message,
  }) : this._(
         status: FeedbackSubmissionStatus.success,
         rating: rating,
         message: message,
       );

  const FeedbackSubmissionState.failure({
    required int rating,
    required String message,
  }) : this._(
         status: FeedbackSubmissionStatus.failure,
         rating: rating,
         message: message,
       );

  final FeedbackSubmissionStatus status;
  final int rating;
  final String? message;

  bool get isSubmitting => status == FeedbackSubmissionStatus.submitting;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackSubmissionState &&
            status == other.status &&
            rating == other.rating &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(status, rating, message);
}
