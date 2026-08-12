import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/application/signup_controller.dart';
import 'package:kku_ottae/features/auth/application/signup_state.dart';
import 'package:kku_ottae/features/auth/domain/auth_failure.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';
import 'package:kku_ottae/features/profile/application/profile_providers.dart';
import 'package:kku_ottae/features/profile/domain/user_profile_failure.dart';

import '../../profile/fakes/fake_user_profile_repository.dart';
import '../fakes/fake_auth_repository.dart';

void main() {
  const createdUser = AuthUser(
    id: 'user-1',
    email: 'student@kku.ac.kr',
    isEmailVerified: false,
  );
  const verifiedUser = AuthUser(
    id: 'user-1',
    email: 'student@kku.ac.kr',
    isEmailVerified: true,
  );

  group('SignupController', () {
    final invalidInputs =
        <
          ({
            String description,
            String email,
            String password,
            String confirmPassword,
            String message,
          })
        >[
          (
            description: '빈 필드',
            email: '',
            password: 'password',
            confirmPassword: 'password',
            message: SignupController.missingAccountFieldsMessage,
          ),
          (
            description: '학교 도메인이 아닌 이메일',
            email: 'student@example.com',
            password: 'password',
            confirmPassword: 'password',
            message: SignupController.invalidSchoolEmailMessage,
          ),
          (
            description: '일치하지 않는 비밀번호',
            email: 'student@kku.ac.kr',
            password: 'password',
            confirmPassword: 'different',
            message: SignupController.passwordMismatchMessage,
          ),
        ];

    for (final input in invalidInputs) {
      test('${input.description}을 검증하고 계정을 만들지 않는다', () async {
        final authRepository = FakeAuthRepository();
        final profileRepository = FakeUserProfileRepository();
        final harness = _createHarness(authRepository, profileRepository);
        addTearDown(harness.dispose);

        await harness.controller.requestEmailVerification(
          email: input.email,
          password: input.password,
          confirmPassword: input.confirmPassword,
        );

        expect(harness.state.status, SignupStatus.failure);
        expect(harness.state.message, input.message);
        expect(authRepository.createUserRequests, isEmpty);
      });
    }

    test('계정을 생성하고 인증 메일 전송 상태로 전환한다', () async {
      final authRepository = FakeAuthRepository(
        createUser: (_, _) async => createdUser,
        sendEmailVerification: () async {},
      );
      final profileRepository = FakeUserProfileRepository();
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);

      await _requestVerification(harness.controller);

      expect(
        harness.states,
        contains(SignupState.loading(action: SignupAction.requestVerification)),
      );
      expect(harness.state.status, SignupStatus.verificationEmailSent);
      expect(harness.state.user, createdUser);
      expect(
        authRepository.createUserRequests.single.email,
        'student@kku.ac.kr',
      );
      expect(authRepository.createUserRequests.single.password, 'password');
      expect(authRepository.emailVerificationRequestCount, 1);
    });

    test('메일 전송 실패 후 재시도해도 계정을 다시 만들지 않는다', () async {
      var shouldFail = true;
      final authRepository = FakeAuthRepository(
        createUser: (_, _) async => createdUser,
        sendEmailVerification: () async {
          if (shouldFail) {
            shouldFail = false;
            throw const AuthFailure(
              reason: AuthFailureReason.networkUnavailable,
            );
          }
        },
      );
      final profileRepository = FakeUserProfileRepository();
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);

      await _requestVerification(harness.controller);

      expect(harness.state.status, SignupStatus.failure);
      expect(harness.state.user, createdUser);
      expect(harness.state.message, '네트워크 연결을 확인해주세요.');

      await _requestVerification(harness.controller);

      expect(harness.state.status, SignupStatus.verificationEmailSent);
      expect(authRepository.createUserRequests.length, 1);
      expect(authRepository.emailVerificationRequestCount, 2);
    });

    test('이미 가입된 이메일 오류를 회원가입 메시지로 변환한다', () async {
      final authRepository = FakeAuthRepository(
        createUser: (_, _) async => throw const AuthFailure(
          reason: AuthFailureReason.emailAlreadyInUse,
        ),
      );
      final profileRepository = FakeUserProfileRepository();
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);

      await _requestVerification(harness.controller);

      expect(harness.state.status, SignupStatus.failure);
      expect(harness.state.message, '이미 가입된 이메일입니다.');
    });

    test('인증되지 않은 이메일을 다시 확인해 인증 완료 상태로 전환한다', () async {
      var reloadCount = 0;
      final authRepository = FakeAuthRepository(
        createUser: (_, _) async => createdUser,
        sendEmailVerification: () async {},
        reloadCurrentUser: () async {
          reloadCount++;
          return reloadCount == 1 ? createdUser : verifiedUser;
        },
      );
      final profileRepository = FakeUserProfileRepository();
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);
      await _requestVerification(harness.controller);

      await harness.controller.checkEmailVerification();

      expect(harness.state.status, SignupStatus.emailNotVerified);
      expect(harness.state.message, SignupController.emailNotVerifiedMessage);

      await harness.controller.checkEmailVerification();

      expect(harness.state.status, SignupStatus.emailVerified);
      expect(harness.state.user, verifiedUser);
      expect(authRepository.reloadCurrentUserRequestCount, 2);
    });

    test('진행 중인 계정 생성과 겹치는 후속 요청을 건너뛴다', () async {
      final createResponse = Completer<AuthUser>();
      final authRepository = FakeAuthRepository(
        createUser: (_, _) => createResponse.future,
        sendEmailVerification: () async {},
      );
      final profileRepository = FakeUserProfileRepository();
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);

      final request = _requestVerification(harness.controller);
      await harness.container.pump();
      await harness.controller.checkEmailVerification();
      await harness.controller.completeSignup(
        name: '홍길동',
        studentId: '20240001',
      );

      expect(harness.state.status, SignupStatus.loading);
      expect(authRepository.reloadCurrentUserRequestCount, 0);
      expect(profileRepository.savedProfiles, isEmpty);

      createResponse.complete(createdUser);
      await request;
      expect(harness.state.status, SignupStatus.verificationEmailSent);
    });

    test('인증 완료 후 이름과 학번을 검증한다', () async {
      final authRepository = _verifiedAuthRepository(
        createdUser: createdUser,
        verifiedUser: verifiedUser,
      );
      final profileRepository = FakeUserProfileRepository();
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);
      await _prepareVerifiedSignup(harness.controller);

      await harness.controller.completeSignup(name: ' ', studentId: '20240001');

      expect(harness.state.status, SignupStatus.failure);
      expect(
        harness.state.message,
        SignupController.missingProfileFieldsMessage,
      );
      expect(profileRepository.savedProfiles, isEmpty);
    });

    test('인증된 사용자 프로필을 정리해 저장하고 가입을 완료한다', () async {
      final authRepository = _verifiedAuthRepository(
        createdUser: createdUser,
        verifiedUser: verifiedUser,
      );
      final profileRepository = FakeUserProfileRepository();
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);
      await _prepareVerifiedSignup(harness.controller);

      await harness.controller.completeSignup(
        name: '  홍길동 ',
        studentId: ' 20240001 ',
      );

      expect(harness.state.status, SignupStatus.completed);
      expect(harness.state.message, SignupController.signupCompletedMessage);
      final profile = profileRepository.savedProfiles.single;
      expect(profile.userId, 'user-1');
      expect(profile.name, '홍길동');
      expect(profile.studentId, '20240001');
      expect(profile.email, 'student@kku.ac.kr');
    });

    test('프로필 저장 실패 후 저장만 다시 시도해 가입을 완료한다', () async {
      var shouldFail = true;
      final authRepository = _verifiedAuthRepository(
        createdUser: createdUser,
        verifiedUser: verifiedUser,
      );
      final profileRepository = FakeUserProfileRepository(
        saveProfile: (_) async {
          if (shouldFail) {
            shouldFail = false;
            throw const UserProfileFailure(
              reason: UserProfileFailureReason.temporarilyUnavailable,
            );
          }
        },
      );
      final harness = _createHarness(authRepository, profileRepository);
      addTearDown(harness.dispose);
      await _prepareVerifiedSignup(harness.controller);

      await harness.controller.completeSignup(
        name: '홍길동',
        studentId: '20240001',
      );

      expect(harness.state.status, SignupStatus.failure);
      expect(harness.state.user, verifiedUser);
      expect(harness.state.message, contains('다시 시도'));

      await harness.controller.completeSignup(
        name: '홍길동',
        studentId: '20240001',
      );

      expect(harness.state.status, SignupStatus.completed);
      expect(profileRepository.savedProfiles.length, 2);
      expect(authRepository.createUserRequests.length, 1);
    });
  });
}

FakeAuthRepository _verifiedAuthRepository({
  required AuthUser createdUser,
  required AuthUser verifiedUser,
}) {
  return FakeAuthRepository(
    createUser: (_, _) async => createdUser,
    sendEmailVerification: () async {},
    reloadCurrentUser: () async => verifiedUser,
  );
}

Future<void> _requestVerification(SignupController controller) {
  return controller.requestEmailVerification(
    email: 'student@kku.ac.kr',
    password: 'password',
    confirmPassword: 'password',
  );
}

Future<void> _prepareVerifiedSignup(SignupController controller) async {
  await _requestVerification(controller);
  await controller.checkEmailVerification();
}

_SignupHarness _createHarness(
  FakeAuthRepository authRepository,
  FakeUserProfileRepository profileRepository,
) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      userProfileRepositoryProvider.overrideWithValue(profileRepository),
    ],
  );
  final states = <SignupState>[];
  final subscription = container.listen(
    signupControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _SignupHarness(
    container: container,
    subscription: subscription,
    states: states,
  );
}

final class _SignupHarness {
  const _SignupHarness({
    required this.container,
    required this.subscription,
    required this.states,
  });

  final ProviderContainer container;
  final ProviderSubscription<SignupState> subscription;
  final List<SignupState> states;

  SignupState get state => container.read(signupControllerProvider);

  SignupController get controller {
    return container.read(signupControllerProvider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}
