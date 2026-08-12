import 'package:kku_ottae/features/feedback/domain/feedback_repository.dart';
import 'package:kku_ottae/features/feedback/domain/feedback_submission.dart';

typedef FakeSubmitFeedbackHandler =
    Future<void> Function(FeedbackSubmission submission);

final class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository({FakeSubmitFeedbackHandler? submitFeedback})
    : _submitFeedback = submitFeedback ?? _submitSuccessfully;

  final FakeSubmitFeedbackHandler _submitFeedback;
  final List<FeedbackSubmission> submissions = [];

  @override
  Future<void> submitFeedback(FeedbackSubmission submission) {
    submissions.add(submission);
    return _submitFeedback(submission);
  }

  static Future<void> _submitSuccessfully(FeedbackSubmission _) async {}
}
