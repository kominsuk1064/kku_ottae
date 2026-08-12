import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kku_ottae/features/feedback/application/feedback_submission_controller.dart';
import 'package:kku_ottae/features/feedback/application/feedback_submission_state.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  static const _ratingKey = ValueKey('feedback-rating');
  static const _commentFieldKey = ValueKey('feedback-comment-field');
  static const _messageKey = ValueKey('feedback-message');
  static const _submitButtonKey = ValueKey('feedback-submit-button');

  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedbackSubmissionControllerProvider);
    ref.listen<FeedbackSubmissionState>(
      feedbackSubmissionControllerProvider,
      _handleStateChange,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('피드백 보내기')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '앱 전반에 대한 만족도를 남겨주세요!',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      key: _ratingKey,
                      label: '만족도 ${state.rating}점',
                      child: RatingBar.builder(
                        initialRating: state.rating.toDouble(),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        ignoreGestures: state.isSubmitting,
                        itemCount: 5,
                        itemSize: 40,
                        itemBuilder: (_, __) =>
                            const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (value) => ref
                            .read(feedbackSubmissionControllerProvider.notifier)
                            .updateRating(value.toInt()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: _commentFieldKey,
                    controller: _commentController,
                    readOnly: state.isSubmitting,
                    maxLines: 5,
                    maxLength: 300,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: '코멘트를 입력해 주세요 (5자 이상)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    child: state.status != FeedbackSubmissionStatus.failure
                        ? null
                        : Center(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                state.message!,
                                key: _messageKey,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFB3261E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: _submitButtonKey,
                      onPressed: state.isSubmitting ? null : _submitFeedback,
                      child: state.isSubmitting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              state.status == FeedbackSubmissionStatus.failure
                                  ? '다시 시도'
                                  : '보내기',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitFeedback() {
    FocusScope.of(context).unfocus();
    ref
        .read(feedbackSubmissionControllerProvider.notifier)
        .submit(comment: _commentController.text);
  }

  void _handleStateChange(
    FeedbackSubmissionState? previous,
    FeedbackSubmissionState next,
  ) {
    if (!mounted ||
        next.status != FeedbackSubmissionStatus.success ||
        previous?.status == FeedbackSubmissionStatus.success) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            next.message ?? FeedbackSubmissionController.successMessage,
          ),
        ),
      );
    Navigator.pop(context);
  }
}
