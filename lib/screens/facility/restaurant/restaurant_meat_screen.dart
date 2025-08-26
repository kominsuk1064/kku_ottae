import 'package:flutter/material.dart';

class RestaurantMeatScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const RestaurantMeatScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<RestaurantMeatScreen> createState() => _RestaurantMeatScreenState();
}

class _RestaurantMeatScreenState extends State<RestaurantMeatScreen> {
  final Map<String, List<Map<String, String>>> groupedRestaurants = const {
    '신촌 · 단월': [
      {'name': '돈사랑포차', 'menu': '고기', 'location': '충북 충주시 단월동 484'},
      {
        'name': '바베큐에꼬치다',
        'menu': '꼬치구이류',
        'location': '충북 충주시 충열4길 21 1층 바베큐에 꼬치다',
      },
      {'name': '한성대패', 'menu': '대패삼겹살', 'location': '충북 충주시 충열1길 20-4'},
      {'name': '만복식당', 'menu': '고기', 'location': '충북 충주시 하단2길 4-1'},
      {'name': '동아리왕족발보쌈', 'menu': '족발/보쌈', 'location': '충북 충주시 하단4길 22'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '족발, 보쌈, 고기, 꼬치',
          style: TextStyle(color: Colors.white),
        ),
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
              }).toList(),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}
