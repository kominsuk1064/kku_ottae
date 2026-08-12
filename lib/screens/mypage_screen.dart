import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kku_ottae/features/auth/presentation/session_sign_out_builder.dart';
import 'feedback_screen.dart'; // 피드백 화면 import
import 'change_password_screen.dart'; // 비밀번호 변경 화면 import

class MyPageScreen extends StatefulWidget {
  final Set<String> myFavorites;

  const MyPageScreen({super.key, required this.myFavorites});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? name;
  String? studentId;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          name = data?['name'] ?? '';
          studentId = data?['studentId'] ?? '';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to fetch user profile: $e\n$stackTrace');
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('내 정보', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            // 사용자 정보 박스
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이름: ${name ?? '불러오는 중...'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '학번: ${studentId ?? ''}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
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
    );
  }
}
