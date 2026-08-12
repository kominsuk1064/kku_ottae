import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kku_ottae/features/auth/presentation/session_sign_out_builder.dart';
import 'package:kku_ottae/features/profile/application/user_profile_controller.dart';
import 'package:kku_ottae/features/profile/application/user_profile_state.dart';
import 'package:kku_ottae/features/profile/domain/user_profile.dart';
import 'feedback_screen.dart'; // 피드백 화면 import
import 'change_password_screen.dart'; // 비밀번호 변경 화면 import

class MyPageScreen extends ConsumerWidget {
  final Set<String> myFavorites;

  const MyPageScreen({super.key, required this.myFavorites});

  Widget buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: const Color(0xFF00552E)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('내 정보', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _UserProfileCard(
                  state: profileState,
                  onRetry: () =>
                      ref.read(userProfileControllerProvider.notifier).retry(),
                ),
                const SizedBox(height: 30),
                buildMenuCard(
                  icon: Icons.star,
                  title: '즐겨찾기',
                  subtitle: '즐겨찾기한 항목 보기',
                  onTap: () {
                    Navigator.pushNamed(context, '/favorites');
                  },
                ),
                buildMenuCard(
                  icon: Icons.feedback,
                  title: '피드백 보내기',
                  subtitle: '앱 개선을 위한 의견 남기기',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                    );
                  },
                ),
                buildMenuCard(
                  icon: Icons.lock,
                  title: '비밀번호 변경',
                  subtitle: '비밀번호를 변경합니다',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                SessionSignOutBuilder(
                  onSignedOut: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  ),
                  builder: (context, state, signOut) => buildMenuCard(
                    icon: Icons.logout,
                    title: '로그아웃',
                    subtitle: state.isSigningOut ? '로그아웃 중...' : '계정에서 로그아웃',
                    onTap: state.isSigningOut ? null : signOut,
                    trailing: state.isSigningOut
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.state, required this.onRetry});

  static const loadingKey = ValueKey('user-profile-loading');
  static const emptyKey = ValueKey('user-profile-empty');
  static const successKey = ValueKey('user-profile-success');
  static const errorKey = ValueKey('user-profile-error');
  static const retryButtonKey = ValueKey('user-profile-retry-button');

  final UserProfileState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: switch (state.status) {
        UserProfileStatus.loading => const _ProfileLoading(),
        UserProfileStatus.empty => _ProfileMessage(
          key: emptyKey,
          icon: Icons.person_off_outlined,
          message: '저장된 프로필 정보가 없습니다.',
          actionLabel: '다시 불러오기',
          onRetry: onRetry,
        ),
        UserProfileStatus.success => _ProfileDetails(profile: state.profile!),
        UserProfileStatus.failure => _ProfileMessage(
          key: errorKey,
          icon: Icons.error_outline,
          message: state.message ?? '프로필을 불러오지 못했습니다.',
          actionLabel: '다시 시도',
          onRetry: onRetry,
        ),
      },
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: _UserProfileCard.loadingKey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Flexible(child: Text('프로필을 불러오는 중...')),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: _UserProfileCard.successKey,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이름: ${profile.name}', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text('학번: ${profile.studentId}', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final messageRow = Row(
      children: [
        Icon(icon, color: const Color(0xFF00552E)),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    );
    final action = TextButton.icon(
      key: _UserProfileCard.retryButtonKey,
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: Text(actionLabel),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              messageRow,
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: messageRow),
            const SizedBox(width: 8),
            action,
          ],
        );
      },
    );
  }
}
