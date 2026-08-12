import '../domain/user_profile.dart';

UserProfile? parseUserProfileDocument({
  required String userId,
  required Map<String, dynamic>? data,
}) {
  if (data == null) {
    return null;
  }

  return UserProfile(
    userId: userId,
    name: _stringValue(data['name']),
    studentId: _stringValue(data['studentId']),
    email: _nullableStringValue(data['email']),
  );
}

String _stringValue(Object? value) => value is String ? value : '';

String? _nullableStringValue(Object? value) {
  return value is String ? value : null;
}
