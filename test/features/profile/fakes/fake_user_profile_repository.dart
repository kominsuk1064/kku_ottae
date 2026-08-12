import 'package:kku_ottae/features/profile/domain/user_profile.dart';
import 'package:kku_ottae/features/profile/domain/user_profile_repository.dart';

typedef FakeSaveProfileHandler = Future<void> Function(UserProfile profile);

final class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({FakeSaveProfileHandler? saveProfile})
    : _saveProfile = saveProfile ?? _saveSuccessfully;

  final FakeSaveProfileHandler _saveProfile;

  final List<UserProfile> savedProfiles = [];

  @override
  Future<void> saveProfile(UserProfile profile) {
    savedProfiles.add(profile);
    return _saveProfile(profile);
  }

  static Future<void> _saveSuccessfully(UserProfile profile) async {}
}
