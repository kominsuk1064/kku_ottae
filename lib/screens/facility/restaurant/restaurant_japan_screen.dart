import 'package:flutter/material.dart';

class RestaurantJapanScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const RestaurantJapanScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<RestaurantJapanScreen> createState() => _RestaurantJapanScreenState();
}

class _RestaurantJapanScreenState extends State<RestaurantJapanScreen> {
  final Map<String, List<Map<String, String>>> groupedRestaurants = const {
    '신촌 · 단월': [
      {'name': '아러이', 'menu': '쌀국수', 'location': '충북 충주시 충열5길 21 1층'},
    ],
    '모시래 마을': [
      {'name': '스시마당', 'menu': '초밥, 덮밥', 'location': '충북 충주시 모시래1길 31'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일식, 아시안', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: groupedRestaurants.entries.map((entry) {
          final areaName = entry.key;
          final restaurants = entry.value;
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
              ...restaurants.map((restaurant) {
                final String itemKey =
                    'restaurant-${restaurant['name']}|${restaurant['menu']}|${restaurant['location']}';
                final bool isFavorited = widget.favorites.any(
                  (f) => f.startsWith('restaurant-${restaurant['name']}|'),
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
                              restaurant['name']!,
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
                        Text(
                          '메뉴: ${restaurant['menu']}',
                          style: const TextStyle(fontSize: 14),
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
                              restaurant['location']!,
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
