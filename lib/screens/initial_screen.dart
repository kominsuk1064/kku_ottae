import 'package:flutter/material.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 20.0 : 24.0;
            final verticalPadding = constraints.maxHeight < 500 ? 16.0 : 24.0;
            final logoHeight = (constraints.maxHeight * 0.32).clamp(
              120.0,
              260.0,
            );
            final contentGap = (constraints.maxHeight * 0.10).clamp(24.0, 80.0);

            return SingleChildScrollView(
              key: const ValueKey('initial-scroll-view'),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - verticalPadding * 2)
                      .clamp(0, double.infinity),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo_vertical.png',
                          key: const ValueKey('initial-logo'),
                          width: double.infinity,
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: contentGap),
                        _buildActionButton(
                          key: const ValueKey('initial-login-button'),
                          label: '로그인',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          key: const ValueKey('initial-join-button'),
                          label: '회원가입',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/join'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: key,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
