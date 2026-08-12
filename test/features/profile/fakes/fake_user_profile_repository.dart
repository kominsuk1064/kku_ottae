import 'package:kku_ottae/features/profile/domain/user_profile.dart';
import 'package:kku_ottae/features/profile/domain/user_profile_repository.dart';

typedef FakeSaveProfileHandler = Future<void> Function(UserProfile profile);
typedef FakeFetchProfileHandler = Future<UserProfile?> Function(String userId);

final class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({
    FakeFetchProfileHandler? fetchProfile,
    FakeSaveProfileHandler? saveProfile,
  }) : _fetchProfile = fetchProfile ?? _unexpectedFetch,
       _saveProfile = saveProfile ?? _saveSuccessfully;

  final FakeFetchProfileHandler _fetchProfile;
  final FakeSaveProfileHandler _saveProfile;

  final List<String> fetchedUserIds = [];
  final List<UserProfile> savedProfiles = [];

  @override
  Future<UserProfile?> fetchProfile({required String userId}) {
    fetchedUserIds.add(userId);
    return _fetchProfile(userId);
  }

  @override
  Future<void> saveProfile(UserProfile profile) {
    savedProfiles.add(profile);
    return _saveProfile(profile);
  }

  static Future<void> _saveSuccessfully(UserProfile profile) async {}

  static Future<UserProfile?> _unexpectedFetch(String userId) {
    throw StateError('Unexpected profile fetch for $userId.');
  }
}
