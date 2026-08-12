import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';
import 'package:kku_ottae/features/feedback/application/feedback_providers.dart';
import 'package:kku_ottae/features/feedback/application/feedback_submission_controller.dart';
import 'package:kku_ottae/features/feedback/domain/feedback_failure.dart';
import 'package:kku_ottae/features/feedback/domain/feedback_submission.dart';
import 'package:kku_ottae/screens/feedback_screen.dart';

import '../../auth/fakes/fake_auth_repository.dart';
import '../fakes/fake_feedback_repository.dart';

void main() {
  group('FeedbackScreen', () {
    testWidgets('짧은 코멘트 오류를 표시하고 제출하지 않는다', (tester) async {
      final repository = FakeFeedbackRepository();
      await _pumpFeedbackScreen(tester, repository);

      await tester.enterText(
        find.byKey(const ValueKey('feedback-comment-field')),
        '짧음',
      );
      await tester.tap(find.byKey(const ValueKey('feedback-submit-button')));
      await tester.pump();

      expect(
        find.text(FeedbackSubmissionController.commentTooShortMessage),
        findsOneWidget,
      );
      expect(find.text('다시 시도'), findsOneWidget);
      expect(repository.submissions, isEmpty);
    });

    testWidgets('제출 중 loading을 표시하고 성공하면 이전 화면으로 돌아간다', (tester) async {
      final response = Completer<void>();
      final repository = FakeFeedbackRepository(
        submitFeedback: (_) => response.future,
      );
      await _pumpFeedbackScreen(tester, repository);
      await _enterValidComment(tester);

      final button = find.byKey(const ValueKey('feedback-submit-button'));
      await tester.tap(button);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('feedback-comment-field')),
            )
            .readOnly,
        isTrue,
      );

      response.complete();
      await tester.pumpAndSettle();

      expect(find.text('내 정보 화면'), findsOneWidget);
      expect(
        repository.submissions.single,
        const FeedbackSubmission(
          userId: 'user-1',
          rating: 5,
          comment: '앱이 정말 편리해요',
        ),
      );
    });

    testWidgets('Firestore 오류를 숨기고 다시 시도하면 정상 전송한다', (tester) async {
      var shouldFail = true;
      final repository = FakeFeedbackRepository(
        submitFeedback: (_) async {
          if (shouldFail) {
            shouldFail = false;
            throw const FeedbackFailure(
              reason: FeedbackFailureReason.permissionDenied,
              debugMessage: 'sensitive firestore details',
            );
          }
        },
      );
      await _pumpFeedbackScreen(tester, repository);
      await _enterValidComment(tester);

      final button = find.byKey(const ValueKey('feedback-submit-button'));
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(
        find.text(FeedbackSubmissionController.permissionDeniedMessage),
        findsOneWidget,
      );
      expect(find.textContaining('sensitive'), findsNothing);
      expect(find.byType(FeedbackScreen), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('내 정보 화면'), findsOneWidget);
      expect(repository.submissions.length, 2);
    });

    testWidgets('작은 화면에서도 피드백 폼을 스크롤할 수 있다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FakeFeedbackRepository(
        submitFeedback: (_) async => throw const FeedbackFailure(
          reason: FeedbackFailureReason.temporarilyUnavailable,
        ),
      );
      await _pumpFeedbackScreen(tester, repository);
      await _enterValidComment(tester);

      await tester.tap(find.byKey(const ValueKey('feedback-submit-button')));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.text(FeedbackSubmissionController.unavailableMessage),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

const testAuthUser = AuthUser(
  id: 'user-1',
  email: 'student@kku.ac.kr',
  isEmailVerified: true,
);

Future<void> _pumpFeedbackScreen(
  WidgetTester tester,
  FakeFeedbackRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(currentUser: testAuthUser),
        ),
        feedbackRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        routes: {
          '/': (_) => const _AccountScreen(),
          '/feedback': (_) => const FeedbackScreen(),
        },
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-feedback')));
  await tester.pumpAndSettle();
}

Future<void> _enterValidComment(WidgetTester tester) {
  return tester.enterText(
    find.byKey(const ValueKey('feedback-comment-field')),
    '앱이 정말 편리해요',
  );
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('내 정보 화면'),
          ElevatedButton(
            key: const ValueKey('open-feedback'),
            onPressed: () => Navigator.pushNamed(context, '/feedback'),
            child: const Text('피드백 열기'),
          ),
        ],
      ),
    );
  }
}
