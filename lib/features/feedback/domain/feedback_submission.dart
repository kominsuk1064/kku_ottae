final class FeedbackSubmission {
  const FeedbackSubmission({
    required this.userId,
    required this.rating,
    required this.comment,
  }) : assert(rating >= 1 && rating <= 5);

  final String userId;
  final int rating;
  final String comment;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackSubmission &&
            userId == other.userId &&
            rating == other.rating &&
            comment == other.comment;
  }

  @override
  int get hashCode => Object.hash(userId, rating, comment);
}
