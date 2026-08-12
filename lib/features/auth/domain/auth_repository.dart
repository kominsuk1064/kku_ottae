import 'auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser> signIn({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});
}
