import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kku_ottae/features/auth/application/login_controller.dart';
import 'package:kku_ottae/features/auth/application/login_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _emailFieldKey = ValueKey('login-email-field');
  static const _passwordFieldKey = ValueKey('login-password-field');
  static const _passwordResetButtonKey = ValueKey('password-reset-button');
  static const _loginButtonKey = ValueKey('login-button');
  static const _feedbackKey = ValueKey('login-feedback');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    ref.listen<LoginState>(loginControllerProvider, _handleStateChange);

    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('로그인', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
                        key: _emailFieldKey,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: '건국대학교 이메일 (@kku.ac.kr)',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: _passwordFieldKey,
                        controller: _passwordController,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: state.isLoading ? null : (_) => _signIn(),
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: _passwordResetButtonKey,
                          onPressed: state.isLoading
                              ? null
                              : _sendPasswordResetEmail,
                          child: SizedBox(
                            width: 120,
                            height: 24,
                            child: Center(
                              child: state.isResettingPassword
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('비밀번호 찾기'),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 48,
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
                      const SizedBox(height: 12),
                      ElevatedButton(
                        key: _loginButtonKey,
                        onPressed: state.isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: SizedBox(
                          width: 64,
                          height: 20,
                          child: Center(
                            child: state.isSigningIn
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '로그인',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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

  void _signIn() {
    FocusScope.of(context).unfocus();
    ref
        .read(loginControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  void _sendPasswordResetEmail() {
    FocusScope.of(context).unfocus();
    ref
        .read(loginControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text);
  }

  void _handleStateChange(LoginState? previous, LoginState next) {
    if (!mounted ||
        next.status != LoginStatus.authenticated ||
        previous?.status == LoginStatus.authenticated) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(next.message ?? '로그인에 성공했습니다.')));
    Navigator.pushReplacementNamed(context, '/home');
  }

  Color _feedbackColor(LoginStatus status) {
    return status == LoginStatus.passwordResetSent
        ? const Color(0xFF00552E)
        : const Color(0xFFB3261E);
  }
}
