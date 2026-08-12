import 'feedback_submission.dart';

abstract interface class FeedbackRepository {
  Future<void> submitFeedback(FeedbackSubmission submission);
}
