final class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.studentId,
    required this.email,
  });

  final String userId;
  final String name;
  final String studentId;
  final String? email;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfile &&
            userId == other.userId &&
            name == other.name &&
            studentId == other.studentId &&
            email == other.email;
  }

  @override
  int get hashCode => Object.hash(userId, name, studentId, email);
}
