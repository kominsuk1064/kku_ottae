import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'firebase_auth_failure_mapper.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          reason: AuthFailureReason.unknown,
          debugMessage: 'Firebase returned a credential without a user.',
        );
      }

      return AuthUser(
        id: user.uid,
        email: user.email,
        isEmailVerified: user.emailVerified,
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirebaseAuthFailure(error), stackTrace);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirebaseAuthFailure(error), stackTrace);
    }
  }
}
