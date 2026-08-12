import 'user_profile.dart';

abstract interface class UserProfileRepository {
  Future<UserProfile?> fetchProfile({required String userId});

  Future<void> saveProfile(UserProfile profile);
}
