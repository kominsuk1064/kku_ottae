import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import 'firestore_user_profile_failure_mapper.dart';
import 'user_profile_document_parser.dart';

final class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile?> fetchProfile({required String userId}) async {
    try {
      final document = await _firestore.collection('users').doc(userId).get();
      return parseUserProfileDocument(userId: userId, data: document.data());
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        mapFirestoreUserProfileFailure(error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.userId).set({
        'name': profile.name,
        'studentId': profile.studentId,
        'email': profile.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        mapFirestoreUserProfileFailure(error),
        stackTrace,
      );
    }
  }
}
