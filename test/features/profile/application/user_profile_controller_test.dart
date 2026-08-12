import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';
import 'package:kku_ottae/features/profile/application/profile_providers.dart';
import 'package:kku_ottae/features/profile/application/user_profile_controller.dart';
import 'package:kku_ottae/features/profile/application/user_profile_state.dart';
import 'package:kku_ottae/features/profile/domain/user_profile.dart';
import 'package:kku_ottae/features/profile/domain/user_profile_failure.dart';

import '../../auth/fakes/fake_auth_repository.dart';
import '../fakes/fake_user_profile_repository.dart';

void main() {
  group('UserProfileController', () {
    test('현재 사용자의 프로필을 조회해 success 상태가 된다', () async {
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) async => testProfile,
      );
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        profileRepository: repository,
      );
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.states.first, const UserProfileState.loading());
      expect(harness.state, const UserProfileState.success(testProfile));
      expect(repository.fetchedUserIds, ['user-1']);
    });

    test('저장된 문서가 없으면 empty 상태가 된다', () async {
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) async => null,
      );
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        profileRepository: repository,
      );
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.state, const UserProfileState.empty());
    });

    test('로그인 사용자가 없으면 Repository를 호출하지 않고 실패한다', () async {
      final repository = FakeUserProfileRepository();
      final harness = _createHarness(
        authRepository: FakeAuthRepository(),
        profileRepository: repository,
      );
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.state.status, UserProfileStatus.failure);
      expect(harness.state.message, UserProfileController.signedOutMessage);
      expect(repository.fetchedUserIds, isEmpty);
    });

    test('Firestore 실패를 안전한 사용자 메시지로 변환하고 재시도한다', () async {
      var shouldFail = true;
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) async {
          if (shouldFail) {
            shouldFail = false;
            throw const UserProfileFailure(
              reason: UserProfileFailureReason.temporarilyUnavailable,
              debugMessage: 'internal firestore details',
            );
          }
          return testProfile;
        },
      );
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        profileRepository: repository,
      );
      addTearDown(harness.dispose);

      await _settle(harness.container);

      expect(harness.state.status, UserProfileStatus.failure);
      expect(harness.state.message, UserProfileController.unavailableMessage);
      expect(harness.state.message, isNot(contains('firestore')));

      await harness.controller.retry();

      expect(harness.state, const UserProfileState.success(testProfile));
      expect(repository.fetchedUserIds, ['user-1', 'user-1']);
    });

    test('진행 중인 조회와 겹치는 요청을 건너뛴다', () async {
      final response = Completer<UserProfile?>();
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) => response.future,
      );
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        profileRepository: repository,
      );
      addTearDown(harness.dispose);

      final firstRequest = harness.controller.load();
      await harness.container.pump();
      final secondRequest = harness.controller.load();

      expect(repository.fetchedUserIds, ['user-1']);
      expect(harness.state.status, UserProfileStatus.loading);

      response.complete(testProfile);
      await Future.wait([firstRequest, secondRequest]);

      expect(harness.state, const UserProfileState.success(testProfile));
    });
  });
}

const testAuthUser = AuthUser(
  id: 'user-1',
  email: 'student@kku.ac.kr',
  isEmailVerified: true,
);

const testProfile = UserProfile(
  userId: 'user-1',
  name: '홍길동',
  studentId: '20240001',
  email: 'student@kku.ac.kr',
);

_UserProfileHarness _createHarness({
  required FakeAuthRepository authRepository,
  required FakeUserProfileRepository profileRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      userProfileRepositoryProvider.overrideWithValue(profileRepository),
    ],
  );
  final states = <UserProfileState>[];
  final subscription = container.listen(
    userProfileControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _UserProfileHarness(
    container: container,
    subscription: subscription,
    states: states,
  );
}

Future<void> _settle(ProviderContainer container) async {
  for (var index = 0; index < 5; index++) {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
  }
}

final class _UserProfileHarness {
  const _UserProfileHarness({
    required this.container,
    required this.subscription,
    required this.states,
  });

  final ProviderContainer container;
  final ProviderSubscription<UserProfileState> subscription;
  final List<UserProfileState> states;

  UserProfileState get state => container.read(userProfileControllerProvider);

  UserProfileController get controller {
    return container.read(userProfileControllerProvider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}
