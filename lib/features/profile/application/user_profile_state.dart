import '../domain/user_profile.dart';

enum UserProfileStatus { loading, empty, success, failure }

final class UserProfileState {
  const UserProfileState._({
    required this.status,
    required this.profile,
    required this.message,
  });

  const UserProfileState.loading()
    : this._(status: UserProfileStatus.loading, profile: null, message: null);

  const UserProfileState.empty()
    : this._(status: UserProfileStatus.empty, profile: null, message: null);

  const UserProfileState.success(UserProfile profile)
    : this._(
        status: UserProfileStatus.success,
        profile: profile,
        message: null,
      );

  const UserProfileState.failure({required String message})
    : this._(
        status: UserProfileStatus.failure,
        profile: null,
        message: message,
      );

  final UserProfileStatus status;
  final UserProfile? profile;
  final String? message;

  bool get isLoading => status == UserProfileStatus.loading;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfileState &&
            status == other.status &&
            profile == other.profile &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(status, profile, message);
}
