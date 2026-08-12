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

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapUser(credential.user);
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirebaseAuthFailure(error), stackTrace);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthFailure(
          reason: AuthFailureReason.noCurrentUser,
          debugMessage: 'Cannot send verification email without a user.',
        );
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirebaseAuthFailure(error), stackTrace);
    }
  }

  @override
  Future<AuthUser> reloadCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthFailure(
          reason: AuthFailureReason.noCurrentUser,
          debugMessage: 'Cannot reload authentication without a user.',
        );
      }
      await user.reload();
      return _mapUser(_firebaseAuth.currentUser);
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirebaseAuthFailure(error), stackTrace);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw const AuthFailure(
          reason: AuthFailureReason.noCurrentUser,
          debugMessage: 'Cannot change password without an email user.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirebaseAuthFailure(error), stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(mapFirebaseAuthFailure(error), stackTrace);
    }
  }

  AuthUser _mapUser(User? user) {
    if (user == null) {
      throw const AuthFailure(
        reason: AuthFailureReason.noCurrentUser,
        debugMessage: 'Firebase returned a credential without a user.',
      );
    }
    return AuthUser(
      id: user.uid,
      email: user.email,
      isEmailVerified: user.emailVerified,
    );
  }
}
