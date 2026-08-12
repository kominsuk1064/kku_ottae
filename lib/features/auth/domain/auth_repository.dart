import 'auth_user.dart';

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Future<AuthUser> signIn({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});

  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<AuthUser> reloadCurrentUser();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signOut();
}
