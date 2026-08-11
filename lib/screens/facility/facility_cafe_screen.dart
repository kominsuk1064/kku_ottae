import 'package:flutter/material.dart';

class FacilityCafeScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const FacilityCafeScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<FacilityCafeScreen> createState() => _FacilityCafeScreenState();
}

class _FacilityCafeScreenState extends State<FacilityCafeScreen> {
  final Map<String, List<Map<String, String>>> groupedCafes = const {
    '신촌 · 단월': [
      {'name': '메가MGC커피', 'menu': '카페', 'location': '충북 충주시 충열5길 24 1층'},
      {'name': '컴포즈커피', 'menu': '요리주점', 'location': '충북 충주시 충열5길 24 1층'},
      {'name': '소소, 단월', 'menu': '디저트', 'location': '충북 충주시 충열5길 12 1층 소소, 단월'},
      {'name': '르비드', 'menu': '카페', 'location': '충북 충주시 충열5길 25 르비드'},
      {'name': '레스티오', 'menu': '카페', 'location': '충북 충주시 충원대로 268(중원도서관 지하)'},
      {
        'name': '애프터눈',
        'menu': '카페, 밀크티',
        'location': '충북 충주시 하단1길 24-2 애프터눈 카페',
      },
      {'name': '카페일노베', 'menu': '카페', 'location': '충북 충주시 충열4길 9-2'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카페', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: groupedCafes.entries.map((entry) {
          final areaName = entry.key;
          final cafes = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                areaName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00552E),
                ),
              ),
              const SizedBox(height: 8),
              ...cafes.map((cafe) {
                final String itemKey =
                    'restaurant-${cafe['name']}|${cafe['menu']}|${cafe['location']}';
                final bool isFavorited = widget.favorites.any(
                  (f) => f.startsWith('restaurant-${cafe['name']}|'),
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
                              cafe['name']!,
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
                        Text('메뉴: ${cafe['menu']}'),
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
                              cafe['location']!,
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
