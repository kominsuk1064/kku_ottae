import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/feedback/data/feedback_document_mapper.dart';
import 'package:kku_ottae/features/feedback/domain/feedback_submission.dart';

void main() {
  test('피드백을 기존 Firestore 문서 필드로 변환한다', () {
    final document = createFeedbackDocument(
      submission: const FeedbackSubmission(
        userId: 'user-1',
        rating: 4,
        comment: '앱이 정말 편리해요',
      ),
      createdAt: 'server-timestamp',
    );

    expect(document, {
      'userId': 'user-1',
      'rating': 4,
      'comment': '앱이 정말 편리해요',
      'createdAt': 'server-timestamp',
    });
  });
}
