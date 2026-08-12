import 'user_profile.dart';

abstract interface class UserProfileRepository {
  Future<void> saveProfile(UserProfile profile);
}
