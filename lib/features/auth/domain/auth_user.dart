final class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
  });

  final String id;
  final String? email;
  final bool isEmailVerified;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser &&
            id == other.id &&
            email == other.email &&
            isEmailVerified == other.isEmailVerified;
  }

  @override
  int get hashCode => Object.hash(id, email, isEmailVerified);
}
