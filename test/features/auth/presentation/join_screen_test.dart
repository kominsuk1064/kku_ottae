import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/application/signup_controller.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';
import 'package:kku_ottae/features/profile/application/profile_providers.dart';
import 'package:kku_ottae/features/profile/domain/user_profile_failure.dart';
import 'package:kku_ottae/screens/join_screen.dart';

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

  group('JoinScreen', () {
    testWidgets('학교 이메일이 아니면 오류를 표시하고 계정을 만들지 않는다', (tester) async {
      final authRepository = FakeAuthRepository();
      final profileRepository = FakeUserProfileRepository();
      await _pumpJoinScreen(tester, authRepository, profileRepository);
      await _enterSignupFields(tester, email: 'student@example.com');

      await _tapRequestVerification(tester);

      expect(
        find.text(SignupController.invalidSchoolEmailMessage),
        findsOneWidget,
      );
      expect(authRepository.createUserRequests, isEmpty);
    });

    testWidgets('계정 생성 중 loading을 표시하고 인증 메일 전송 상태가 된다', (tester) async {
      final createResponse = Completer<AuthUser>();
      final authRepository = FakeAuthRepository(
        createUser: (_, _) => createResponse.future,
        sendEmailVerification: () async {},
      );
      final profileRepository = FakeUserProfileRepository();
      await _pumpJoinScreen(tester, authRepository, profileRepository);
      await _enterSignupFields(tester);

      await tester.tap(
        find.byKey(const ValueKey('request-verification-button')),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('request-verification-button')),
            )
            .onPressed,
        isNull,
      );

      createResponse.complete(createdUser);
      await tester.pumpAndSettle();

      expect(
        find.text(SignupController.verificationEmailSentMessage),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('check-verification-button')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('signup-email-field')))
            .readOnly,
        isTrue,
      );
    });

    testWidgets('이메일 미인증 상태를 다시 확인해 가입 가능한 상태가 된다', (tester) async {
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
      await _pumpJoinScreen(tester, authRepository, profileRepository);
      await _enterSignupFields(tester);
      await _tapRequestVerification(tester);

      await _tapCheckVerification(tester);

      expect(
        find.text(SignupController.emailNotVerifiedMessage),
        findsOneWidget,
      );

      await _tapCheckVerification(tester);

      expect(find.text(SignupController.emailVerifiedMessage), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('complete-signup-button')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('프로필 저장 중 loading을 표시하고 완료 후 로그인 화면으로 이동한다', (tester) async {
      final saveResponse = Completer<void>();
      final authRepository = _verifiedAuthRepository(createdUser, verifiedUser);
      final profileRepository = FakeUserProfileRepository(
        saveProfile: (_) => saveResponse.future,
      );
      await _pumpJoinScreen(tester, authRepository, profileRepository);
      await _enterSignupFields(tester);
      await _prepareVerifiedSignup(tester);

      final completeButton = find.byKey(
        const ValueKey('complete-signup-button'),
      );
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(completeButton).onPressed, isNull);

      saveResponse.complete();
      await tester.pumpAndSettle();

      expect(find.text('로그인 화면'), findsOneWidget);
      expect(profileRepository.savedProfiles.single.name, '홍길동');
    });

    testWidgets('프로필 저장 실패를 표시하고 가입 버튼에서 저장만 재시도한다', (tester) async {
      var shouldFail = true;
      final authRepository = _verifiedAuthRepository(createdUser, verifiedUser);
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
      await _pumpJoinScreen(tester, authRepository, profileRepository);
      await _enterSignupFields(tester);
      await _prepareVerifiedSignup(tester);

      final completeButton = find.byKey(
        const ValueKey('complete-signup-button'),
      );
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('다시 시도'), findsOneWidget);
      expect(find.byType(JoinScreen), findsOneWidget);

      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      expect(find.text('로그인 화면'), findsOneWidget);
      expect(profileRepository.savedProfiles.length, 2);
      expect(authRepository.createUserRequests.length, 1);
    });

    testWidgets('작은 화면에서도 회원가입 폼을 스크롤할 수 있다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final authRepository = FakeAuthRepository();
      final profileRepository = FakeUserProfileRepository();

      await _pumpJoinScreen(tester, authRepository, profileRepository);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

FakeAuthRepository _verifiedAuthRepository(
  AuthUser createdUser,
  AuthUser verifiedUser,
) {
  return FakeAuthRepository(
    createUser: (_, _) async => createdUser,
    sendEmailVerification: () async {},
    reloadCurrentUser: () async => verifiedUser,
  );
}

Future<void> _pumpJoinScreen(
  WidgetTester tester,
  FakeAuthRepository authRepository,
  FakeUserProfileRepository profileRepository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
      ],
      child: MaterialApp(
        routes: {
          '/': (_) => const JoinScreen(),
          '/login': (_) => const Scaffold(body: Center(child: Text('로그인 화면'))),
        },
      ),
    ),
  );
  await tester.pump();
}

Future<void> _enterSignupFields(
  WidgetTester tester, {
  String email = 'student@kku.ac.kr',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('signup-name-field')),
    '홍길동',
  );
  await tester.enterText(
    find.byKey(const ValueKey('signup-student-id-field')),
    '20240001',
  );
  await tester.enterText(
    find.byKey(const ValueKey('signup-email-field')),
    email,
  );
  await tester.enterText(
    find.byKey(const ValueKey('signup-password-field')),
    'password',
  );
  await tester.enterText(
    find.byKey(const ValueKey('signup-confirm-password-field')),
    'password',
  );
}

Future<void> _tapRequestVerification(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('request-verification-button'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _tapCheckVerification(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('check-verification-button'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _prepareVerifiedSignup(WidgetTester tester) async {
  await _tapRequestVerification(tester);
  await _tapCheckVerification(tester);
}
