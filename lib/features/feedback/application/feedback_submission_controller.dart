import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/feedback_failure.dart';
import '../domain/feedback_repository.dart';
import '../domain/feedback_submission.dart';
import 'feedback_providers.dart';
import 'feedback_submission_state.dart';

final feedbackSubmissionControllerProvider =
    NotifierProvider.autoDispose<
      FeedbackSubmissionController,
      FeedbackSubmissionState
    >(FeedbackSubmissionController.new);

final class FeedbackSubmissionController
    extends Notifier<FeedbackSubmissionState> {
  static const commentTooShortMessage = '코멘트를 5자 이상 입력해주세요.';
  static const commentTooLongMessage = '코멘트는 300자 이하로 입력해주세요.';
  static const signedOutMessage = '로그인이 필요합니다.';
  static const successMessage = '피드백이 정상적으로 전송되었습니다!';
  static const permissionDeniedMessage = '피드백을 전송할 권한이 없습니다.';
  static const unavailableMessage = '피드백 서버에 연결할 수 없습니다. 다시 시도해주세요.';
  static const unknownErrorMessage = '피드백을 전송하지 못했습니다. 다시 시도해주세요.';

  late final AuthRepository _authRepository;
  late final FeedbackRepository _feedbackRepository;
  bool _operationInFlight = false;
  bool _disposed = false;

  @override
  FeedbackSubmissionState build() {
    _authRepository = ref.read(authRepositoryProvider);
    _feedbackRepository = ref.read(feedbackRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    return const FeedbackSubmissionState.idle();
  }

  void updateRating(int rating) {
    if (_disposed || state.isSubmitting || rating < 1 || rating > 5) {
      return;
    }
    state = FeedbackSubmissionState.idle(rating: rating);
  }

  Future<void> submit({required String comment}) async {
    if (_disposed || _operationInFlight) {
      return;
    }

    final normalizedComment = comment.trim();
    final validationMessage = _validateComment(normalizedComment);
    if (validationMessage != null) {
      state = FeedbackSubmissionState.failure(
        rating: state.rating,
        message: validationMessage,
      );
      return;
    }

    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      state = FeedbackSubmissionState.failure(
        rating: state.rating,
        message: signedOutMessage,
      );
      return;
    }

    _operationInFlight = true;
    final rating = state.rating;
    state = FeedbackSubmissionState.submitting(rating: rating);
    try {
      await _feedbackRepository.submitFeedback(
        FeedbackSubmission(
          userId: currentUser.id,
          rating: rating,
          comment: normalizedComment,
        ),
      );
      if (_disposed) {
        return;
      }
      state = FeedbackSubmissionState.success(
        rating: rating,
        message: successMessage,
      );
    } on FeedbackFailure catch (error, stackTrace) {
      _reportFeedbackFailure(error, stackTrace, rating: rating);
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(error, stackTrace, rating: rating);
    } finally {
      _operationInFlight = false;
    }
  }

  String? _validateComment(String comment) {
    if (comment.length < 5) {
      return commentTooShortMessage;
    }
    if (comment.length > 300) {
      return commentTooLongMessage;
    }
    return null;
  }

  void _reportFeedbackFailure(
    FeedbackFailure error,
    StackTrace stackTrace, {
    required int rating,
  }) {
    developer.log(
      '피드백 전송 실패',
      name: 'kku_ottae.feedback',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = FeedbackSubmissionState.failure(
      rating: rating,
      message: switch (error.reason) {
        FeedbackFailureReason.permissionDenied ||
        FeedbackFailureReason.unauthenticated => permissionDeniedMessage,
        FeedbackFailureReason.temporarilyUnavailable => unavailableMessage,
        FeedbackFailureReason.unknown => unknownErrorMessage,
      },
    );
  }

  void _reportUnexpectedFailure(
    Object error,
    StackTrace stackTrace, {
    required int rating,
  }) {
    developer.log(
      '예상하지 못한 피드백 전송 오류',
      name: 'kku_ottae.feedback',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = FeedbackSubmissionState.failure(
      rating: rating,
      message: unknownErrorMessage,
    );
  }
}
