import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_user_profile_repository.dart';
import '../domain/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirestoreUserProfileRepository(),
);
