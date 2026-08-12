import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kku_ottae/features/auth/application/change_password_controller.dart';
import 'package:kku_ottae/features/auth/application/change_password_state.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  static const _currentPasswordFieldKey = ValueKey('current-password-field');
  static const _newPasswordFieldKey = ValueKey('new-password-field');
  static const _confirmPasswordFieldKey = ValueKey('confirm-password-field');
  static const _changePasswordButtonKey = ValueKey('change-password-button');
  static const _feedbackKey = ValueKey('change-password-feedback');

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);
    ref.listen<ChangePasswordState>(
      changePasswordControllerProvider,
      _handleStateChange,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: _currentPasswordFieldKey,
                      controller: _currentPasswordController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      readOnly: state.isLoading,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: '현재 비밀번호',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: _newPasswordFieldKey,
                      controller: _newPasswordController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      readOnly: state.isLoading,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: _confirmPasswordFieldKey,
                      controller: _confirmPasswordController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      readOnly: state.isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: state.isLoading
                          ? null
                          : (_) => _changePassword(),
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호 확인',
                        border: OutlineInputBorder(),
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
                        key: _changePasswordButtonKey,
                        onPressed: state.isLoading ? null : _changePassword,
                        child: state.isLoading
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('비밀번호 변경'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changePassword() {
    FocusScope.of(context).unfocus();
    ref
        .read(changePasswordControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
  }

  void _handleStateChange(
    ChangePasswordState? previous,
    ChangePasswordState next,
  ) {
    if (!mounted ||
        next.status != ChangePasswordStatus.success ||
        previous?.status == ChangePasswordStatus.success) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(next.message ?? '비밀번호가 성공적으로 변경되었습니다.')),
      );
    Navigator.pop(context);
  }
}
