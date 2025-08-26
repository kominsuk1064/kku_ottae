import 'package:flutter/material.dart';
import 'package:kku_ottae/screens/facility/campus_map_web_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/mypage'),
                child: Row(
                  children: const [
                    Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 28, // ✅ 아이콘 크기 키움 (기존 기본: 24)
                    ),
                    SizedBox(width: 8),
                    Text(
                      '내 정보',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20, // ✅ 글씨 크기 증가 (기존 16 → 20)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
              Center(
                child: Image.asset(
                  'assets/logo_horizontal.png',
                  width: 700,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 120),
              _buildMenuButton(
                label: '🚌 버스정보',
                onTap: () => Navigator.pushNamed(context, '/bus'),
              ),
              const SizedBox(height: 32),
              _buildMenuButton(
                label: '🏪 편의시설',
                onTap: () => Navigator.pushNamed(context, '/facility'),
              ),
              const SizedBox(height: 32),

              // ✅ 학교지도 버튼 → WebView 페이지 직접 실행
              _buildMenuButton(
                label: '🗺️ 학교지도',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CampusMapWebScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
