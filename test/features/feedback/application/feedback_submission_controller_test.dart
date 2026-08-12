import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/auth/application/auth_providers.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';
import 'package:kku_ottae/features/feedback/application/feedback_providers.dart';
import 'package:kku_ottae/features/feedback/application/feedback_submission_controller.dart';
import 'package:kku_ottae/features/feedback/application/feedback_submission_state.dart';
import 'package:kku_ottae/features/feedback/domain/feedback_failure.dart';
import 'package:kku_ottae/features/feedback/domain/feedback_submission.dart';

import '../../auth/fakes/fake_auth_repository.dart';
import '../fakes/fake_feedback_repository.dart';

void main() {
  group('FeedbackSubmissionController', () {
    test('기본 별점 5점에서 유효한 별점만 변경한다', () {
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        feedbackRepository: FakeFeedbackRepository(),
      );
      addTearDown(harness.dispose);

      expect(harness.state, const FeedbackSubmissionState.idle());

      harness.controller.updateRating(3);
      expect(harness.state, const FeedbackSubmissionState.idle(rating: 3));

      harness.controller.updateRating(0);
      expect(harness.state.rating, 3);
    });

    test('5자 미만 코멘트를 검증하고 Repository를 호출하지 않는다', () async {
      final repository = FakeFeedbackRepository();
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        feedbackRepository: repository,
      );
      addTearDown(harness.dispose);

      await harness.controller.submit(comment: '1234');

      expect(harness.state.status, FeedbackSubmissionStatus.failure);
      expect(
        harness.state.message,
        FeedbackSubmissionController.commentTooShortMessage,
      );
      expect(repository.submissions, isEmpty);
    });

    test('300자를 넘는 코멘트를 검증하고 Repository를 호출하지 않는다', () async {
      final repository = FakeFeedbackRepository();
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        feedbackRepository: repository,
      );
      addTearDown(harness.dispose);
      final comment = List<String>.filled(301, 'a').join();

      await harness.controller.submit(comment: comment);

      expect(harness.state.status, FeedbackSubmissionStatus.failure);
      expect(
        harness.state.message,
        FeedbackSubmissionController.commentTooLongMessage,
      );
      expect(repository.submissions, isEmpty);
    });

    test('로그인 사용자가 없으면 Repository를 호출하지 않는다', () async {
      final repository = FakeFeedbackRepository();
      final harness = _createHarness(
        authRepository: FakeAuthRepository(),
        feedbackRepository: repository,
      );
      addTearDown(harness.dispose);

      await harness.controller.submit(comment: '충분히 긴 코멘트');

      expect(harness.state.status, FeedbackSubmissionStatus.failure);
      expect(
        harness.state.message,
        FeedbackSubmissionController.signedOutMessage,
      );
      expect(repository.submissions, isEmpty);
    });

    test('현재 사용자와 별점, 정리된 코멘트를 저장한다', () async {
      final repository = FakeFeedbackRepository();
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        feedbackRepository: repository,
      );
      addTearDown(harness.dispose);
      harness.controller.updateRating(4);

      await harness.controller.submit(comment: '  앱이 정말 편리해요  ');

      expect(repository.submissions, const [
        FeedbackSubmission(userId: 'user-1', rating: 4, comment: '앱이 정말 편리해요'),
      ]);
      expect(
        harness.states,
        contains(const FeedbackSubmissionState.submitting(rating: 4)),
      );
      expect(
        harness.state,
        const FeedbackSubmissionState.success(
          rating: 4,
          message: FeedbackSubmissionController.successMessage,
        ),
      );
    });

    test('Firestore 실패를 안전한 메시지로 변환하고 다시 제출한다', () async {
      var shouldFail = true;
      final repository = FakeFeedbackRepository(
        submitFeedback: (_) async {
          if (shouldFail) {
            shouldFail = false;
            throw const FeedbackFailure(
              reason: FeedbackFailureReason.temporarilyUnavailable,
              debugMessage: 'internal firestore details',
            );
          }
        },
      );
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        feedbackRepository: repository,
      );
      addTearDown(harness.dispose);

      await harness.controller.submit(comment: '앱이 정말 편리해요');

      expect(harness.state.status, FeedbackSubmissionStatus.failure);
      expect(
        harness.state.message,
        FeedbackSubmissionController.unavailableMessage,
      );
      expect(harness.state.message, isNot(contains('firestore')));

      await harness.controller.submit(comment: '앱이 정말 편리해요');

      expect(harness.state.status, FeedbackSubmissionStatus.success);
      expect(repository.submissions.length, 2);
    });

    test('진행 중인 제출과 겹치는 요청을 건너뛴다', () async {
      final response = Completer<void>();
      final repository = FakeFeedbackRepository(
        submitFeedback: (_) => response.future,
      );
      final harness = _createHarness(
        authRepository: FakeAuthRepository(currentUser: testAuthUser),
        feedbackRepository: repository,
      );
      addTearDown(harness.dispose);

      final firstRequest = harness.controller.submit(comment: '첫 번째 코멘트');
      await harness.container.pump();
      await harness.controller.submit(comment: '두 번째 코멘트');
      harness.controller.updateRating(2);

      expect(repository.submissions.length, 1);
      expect(harness.state.status, FeedbackSubmissionStatus.submitting);
      expect(harness.state.rating, 5);

      response.complete();
      await firstRequest;

      expect(harness.state.status, FeedbackSubmissionStatus.success);
    });
  });
}

const testAuthUser = AuthUser(
  id: 'user-1',
  email: 'student@kku.ac.kr',
  isEmailVerified: true,
);

_FeedbackHarness _createHarness({
  required FakeAuthRepository authRepository,
  required FakeFeedbackRepository feedbackRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      feedbackRepositoryProvider.overrideWithValue(feedbackRepository),
    ],
  );
  final states = <FeedbackSubmissionState>[];
  final subscription = container.listen(
    feedbackSubmissionControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );

  return _FeedbackHarness(
    container: container,
    subscription: subscription,
    states: states,
  );
}

final class _FeedbackHarness {
  const _FeedbackHarness({
    required this.container,
    required this.subscription,
    required this.states,
  });

  final ProviderContainer container;
  final ProviderSubscription<FeedbackSubmissionState> subscription;
  final List<FeedbackSubmissionState> states;

  FeedbackSubmissionState get state {
    return container.read(feedbackSubmissionControllerProvider);
  }

  FeedbackSubmissionController get controller {
    return container.read(feedbackSubmissionControllerProvider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}
