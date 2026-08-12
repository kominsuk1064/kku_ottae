import 'package:flutter/material.dart';
import 'package:kku_ottae/features/campus_map/presentation/campus_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.campusMapBuilder});

  final WidgetBuilder? campusMapBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
            final verticalPadding = constraints.maxHeight < 500 ? 12.0 : 16.0;
            final profileToLogoGap = (constraints.maxHeight * 0.07).clamp(
              16.0,
              56.0,
            );
            final logoHeight = (constraints.maxHeight * 0.18).clamp(
              72.0,
              150.0,
            );
            final logoToMenuGap = (constraints.maxHeight * 0.07).clamp(
              20.0,
              56.0,
            );
            final menuGap = (constraints.maxHeight * 0.025).clamp(12.0, 20.0);

            return SingleChildScrollView(
              key: const ValueKey('home-scroll-view'),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - verticalPadding * 2)
                      .clamp(0, double.infinity),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('home-profile-button'),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/mypage'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.settings, size: 28),
                          label: const Text(
                            '내 정보',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: profileToLogoGap),
                        Center(
                          child: Image.asset(
                            'assets/logo_horizontal.png',
                            key: const ValueKey('home-logo'),
                            width: double.infinity,
                            height: logoHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: logoToMenuGap),
                        _buildMenuButton(
                          key: const ValueKey('home-bus-button'),
                          icon: Icons.directions_bus_outlined,
                          label: '버스정보',
                          onPressed: () => Navigator.pushNamed(context, '/bus'),
                        ),
                        SizedBox(height: menuGap),
                        _buildMenuButton(
                          key: const ValueKey('home-facility-button'),
                          icon: Icons.store_outlined,
                          label: '편의시설',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/facility'),
                        ),
                        SizedBox(height: menuGap),
                        _buildMenuButton(
                          key: const ValueKey('home-map-button'),
                          icon: Icons.map_outlined,
                          label: '학교지도',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    campusMapBuilder ??
                                    (_) => const CampusMapScreen(),
                              ),
                            );
                          },
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

  Widget _buildMenuButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: key,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
