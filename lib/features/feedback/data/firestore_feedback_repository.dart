import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/feedback_repository.dart';
import '../domain/feedback_submission.dart';
import 'feedback_document_mapper.dart';
import 'firestore_feedback_failure_mapper.dart';

final class FirestoreFeedbackRepository implements FeedbackRepository {
  FirestoreFeedbackRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> submitFeedback(FeedbackSubmission submission) async {
    try {
      await _firestore
          .collection('feedbacks')
          .add(
            createFeedbackDocument(
              submission: submission,
              createdAt: FieldValue.serverTimestamp(),
            ),
          );
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirestoreFeedbackFailure(error), stackTrace);
    }
  }
}
