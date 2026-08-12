import 'package:flutter/material.dart';

class FacilityPlaceList extends StatelessWidget {
  const FacilityPlaceList({super.key, required this.sections});

  static const double _maxContentWidth = 720;

  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 400 ? 12.0 : 20.0;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            24,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(children: sections),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FacilitySection extends StatelessWidget {
  const FacilitySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00552E),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class FacilityPlaceCard extends StatelessWidget {
  const FacilityPlaceCard({
    super.key,
    required this.name,
    required this.location,
    required this.isFavorited,
    required this.onFavoriteToggle,
    this.menu,
  });

  final String name;
  final String? menu;
  final String location;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('facility-favorite-$name'),
                  tooltip: isFavorited ? '즐겨찾기 삭제' : '즐겨찾기 추가',
                  icon: Icon(
                    isFavorited ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                  onPressed: onFavoriteToggle,
                ),
              ],
            ),
            if (menu != null) ...[const SizedBox(height: 4), Text('메뉴: $menu')],
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.location_on, size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
