import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kku_ottae/features/auth/application/signup_controller.dart';
import 'package:kku_ottae/features/auth/application/signup_state.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  static const _nameFieldKey = ValueKey('signup-name-field');
  static const _studentIdFieldKey = ValueKey('signup-student-id-field');
  static const _emailFieldKey = ValueKey('signup-email-field');
  static const _passwordFieldKey = ValueKey('signup-password-field');
  static const _confirmPasswordFieldKey = ValueKey(
    'signup-confirm-password-field',
  );
  static const _requestVerificationButtonKey = ValueKey(
    'request-verification-button',
  );
  static const _checkVerificationButtonKey = ValueKey(
    'check-verification-button',
  );
  static const _completeSignupButtonKey = ValueKey('complete-signup-button');
  static const _feedbackKey = ValueKey('signup-feedback');

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupControllerProvider);
    ref.listen<SignupState>(signupControllerProvider, _handleStateChange);

    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        key: _nameFieldKey,
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        readOnly: state.isSavingProfile,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: '이름',
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: _studentIdFieldKey,
                        controller: _studentIdController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        readOnly: state.isSavingProfile,
                        decoration: const InputDecoration(
                          labelText: '학번',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: _emailFieldKey,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        readOnly: state.hasAccount || state.isLoading,
                        autofillHints: const [AutofillHints.username],
                        decoration: InputDecoration(
                          labelText: '건국대학교 이메일 (@kku.ac.kr)',
                          prefixIcon: const Icon(Icons.email),
                          suffixIcon: TextButton(
                            key: _requestVerificationButtonKey,
                            onPressed: state.isLoading || state.isEmailVerified
                                ? null
                                : _requestEmailVerification,
                            child: SizedBox(
                              width: 88,
                              height: 24,
                              child: Center(
                                child: state.isRequestingVerification
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        state.hasAccount ? '인증 재전송' : '인증 요청',
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (state.hasAccount) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            key: _checkVerificationButtonKey,
                            onPressed: state.canCheckVerification
                                ? _checkEmailVerification
                                : null,
                            icon: state.isCheckingVerification
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    state.isEmailVerified
                                        ? Icons.verified
                                        : Icons.mark_email_read,
                                  ),
                            label: Text(
                              state.isEmailVerified ? '인증 완료' : '인증 확인',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        key: _passwordFieldKey,
                        controller: _passwordController,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        readOnly: state.hasAccount || state.isLoading,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: _confirmPasswordFieldKey,
                        controller: _confirmPasswordController,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        readOnly: state.hasAccount || state.isLoading,
                        onSubmitted: state.hasAccount || state.isLoading
                            ? null
                            : (_) => _requestEmailVerification(),
                        decoration: const InputDecoration(
                          labelText: '비밀번호 확인',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      SizedBox(
                        height: 60,
                        child: state.message == null
                            ? null
                            : Center(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    state.message!,
                                    key: _feedbackKey,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _feedbackColor(state.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          key: _completeSignupButtonKey,
                          onPressed: state.canCompleteSignup
                              ? _completeSignup
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00552E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: state.isSavingProfile
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '가입하기',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _requestEmailVerification() {
    FocusScope.of(context).unfocus();
    ref
        .read(signupControllerProvider.notifier)
        .requestEmailVerification(
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
  }

  void _checkEmailVerification() {
    FocusScope.of(context).unfocus();
    ref.read(signupControllerProvider.notifier).checkEmailVerification();
  }

  void _completeSignup() {
    FocusScope.of(context).unfocus();
    ref
        .read(signupControllerProvider.notifier)
        .completeSignup(
          name: _nameController.text,
          studentId: _studentIdController.text,
        );
  }

  void _handleStateChange(SignupState? previous, SignupState next) {
    if (!mounted ||
        next.status != SignupStatus.completed ||
        previous?.status == SignupStatus.completed) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(next.message ?? '회원가입이 완료되었습니다.')));
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Color _feedbackColor(SignupStatus status) {
    return switch (status) {
      SignupStatus.verificationEmailSent ||
      SignupStatus.emailVerified ||
      SignupStatus.completed => const Color(0xFF00552E),
      SignupStatus.idle || SignupStatus.loading => Colors.black87,
      SignupStatus.emailNotVerified ||
      SignupStatus.failure => const Color(0xFFB3261E),
    };
  }
}
