import '../domain/feedback_submission.dart';

Map<String, dynamic> createFeedbackDocument({
  required FeedbackSubmission submission,
  required Object createdAt,
}) {
  return {
    'userId': submission.userId,
    'rating': submission.rating,
    'comment': submission.comment,
    'createdAt': createdAt,
  };
}
