import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';
import 'package:kku_ottae/features/profile/application/profile_providers.dart';
import 'package:kku_ottae/features/profile/application/user_profile_controller.dart';
import 'package:kku_ottae/features/profile/domain/user_profile.dart';
import 'package:kku_ottae/features/profile/domain/user_profile_failure.dart';
import 'package:kku_ottae/screens/mypage_screen.dart';

import '../../auth/fakes/fake_auth_repository.dart';
import '../fakes/fake_user_profile_repository.dart';

void main() {
  group('MyPageScreen', () {
    testWidgets('프로필 조회 중 loading을 표시한다', (tester) async {
      final response = Completer<UserProfile?>();
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) => response.future,
      );

      await _pumpScreen(tester, profileRepository: repository);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('user-profile-loading')),
        findsOneWidget,
      );
      expect(find.text('프로필을 불러오는 중...'), findsOneWidget);
      expect(repository.fetchedUserIds, ['user-1']);

      response.complete(testProfile);
      await tester.pumpAndSettle();
    });

    testWidgets('조회한 이름과 학번을 success 화면에 표시한다', (tester) async {
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) async => testProfile,
      );

      await _pumpScreen(tester, profileRepository: repository);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-profile-success')),
        findsOneWidget,
      );
      expect(find.text('이름: 홍길동'), findsOneWidget);
      expect(find.text('학번: 20240001'), findsOneWidget);
    });

    testWidgets('프로필 문서가 없으면 empty 화면을 표시한다', (tester) async {
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) async => null,
      );

      await _pumpScreen(tester, profileRepository: repository);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('user-profile-empty')), findsOneWidget);
      expect(find.text('저장된 프로필 정보가 없습니다.'), findsOneWidget);
      expect(find.text('다시 불러오기'), findsOneWidget);
    });

    testWidgets('조회 실패 후 다시 시도하면 success 화면으로 복구한다', (tester) async {
      var shouldFail = true;
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) async {
          if (shouldFail) {
            shouldFail = false;
            throw const UserProfileFailure(
              reason: UserProfileFailureReason.permissionDenied,
              debugMessage: 'sensitive firestore details',
            );
          }
          return testProfile;
        },
      );

      await _pumpScreen(tester, profileRepository: repository);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('user-profile-error')), findsOneWidget);
      expect(
        find.text(UserProfileController.permissionDeniedMessage),
        findsOneWidget,
      );
      expect(find.textContaining('sensitive'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('user-profile-retry-button')));
      await tester.pumpAndSettle();

      expect(find.text('이름: 홍길동'), findsOneWidget);
      expect(repository.fetchedUserIds, ['user-1', 'user-1']);
    });

    testWidgets('작은 화면에서도 오류와 전체 메뉴를 스크롤할 수 있다', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeUserProfileRepository(
        fetchProfile: (_) async => throw const UserProfileFailure(
          reason: UserProfileFailureReason.temporarilyUnavailable,
        ),
      );

      await _pumpScreen(tester, profileRepository: repository);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(UserProfileController.unavailableMessage),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('로그아웃'),
        220,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('로그아웃'), findsOneWidget);
      expect(tester.takeException(), isNull);
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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required FakeUserProfileRepository profileRepository,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(currentUser: testAuthUser),
        ),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
      ],
      child: const MaterialApp(home: MyPageScreen(myFavorites: <String>{})),
    ),
  );
}
