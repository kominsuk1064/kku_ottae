import 'package:flutter/material.dart';

class FacilityEtcScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const FacilityEtcScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<FacilityEtcScreen> createState() => _FacilityEtcScreenState();
}

class _FacilityEtcScreenState extends State<FacilityEtcScreen> {
  final Map<String, List<Map<String, String>>> groupedFacilities = const {
    '인쇄': [
      {'name': '중앙제록스', 'location': '충북 충주시 충원대로 242 1층'},
      {'name': '중앙도서관 1층', 'location': '충북 충주시 충원대로 268(중앙도서관 1층)'},
      {'name': '베스트마트문구', 'location': '충북 충주시 충열4길 18'},
      {'name': '학생회관', 'location': '충북 충주시 충원대로 268(학생회관)'},
      {'name': '모시래학사 1층', 'location': '충북 충주시 충원대로 268(모시래학사)'},
    ],
    '뷰티, 미용': [
      {'name': '네일신드롬', 'location': '충북 충주시 모시래2길 42 1층'},
      {'name': '림네일', 'location': '충북 충주시 충열4길 42-5 킹스빌 101호'},
      {'name': '컷트달인', 'location': '충북 충주시 충원대로 268 학생회관 105호'},
      {'name': '왕가네미용', 'location': '충북 충주시 충원대로 242'},
    ],
    '빨래방': [
      {'name': '워시팡팡 셀프빨래방', 'location': '충북 충주시 충열4길 6 1층 102호'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기타 생활시설', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: groupedFacilities.entries.map((entry) {
          final category = entry.key;
          final places = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00552E),
                ),
              ),
              const SizedBox(height: 8),
              ...places.map((place) {
                final itemKey =
                    'restaurant-${place['name']}|편의점/마트|${place['location']}';
                final isFavorited = widget.favorites.any(
                  (f) => f.startsWith('restaurant-${place['name']}|'),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              place['name']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorited ? Icons.star : Icons.star_border,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                widget.toggleFavorite(itemKey);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place['location']!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}
