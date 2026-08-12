import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_feedback_repository.dart';
import '../domain/feedback_repository.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FirestoreFeedbackRepository(),
);
