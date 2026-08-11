import 'package:flutter/material.dart';

class RestaurantChickenScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const RestaurantChickenScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<RestaurantChickenScreen> createState() =>
      _RestaurantChickenScreenState();
}

class _RestaurantChickenScreenState extends State<RestaurantChickenScreen> {
  final Map<String, List<Map<String, String>>> groupedRestaurants = const {
    '신촌 · 단월': [
      {'name': '치킨마루', 'menu': '치킨', 'location': '충북 충주시 충열5길 20'},
      {'name': 'BHC치킨', 'menu': '치킨', 'location': '충북 충주시 충열1길 20-9'},
      {'name': '짱돌', 'menu': '치킨', 'location': '충북 충주시 충열1길 17'},
      {'name': '건대토스트', 'menu': '토스트', 'location': '충북 충주시 충열5길 9-1'},
      {'name': '밀플랜비', 'menu': '수제 핫도그/버거', 'location': '충북 충주시 충열4길 5-7'},
    ],
    '모시래 마을': [
      {'name': '마리노피자', 'menu': '피자', 'location': '충북 충주시 모시래1길 29-1'},
    ],
    '해오름학사': [
      {
        'name': '맘스터치',
        'menu': '햄버거/치킨',
        'location': '충북 충주시 충원대로 266 해오름학사 1층',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '치킨, 피자, 햄버거, 토스트',
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
              }),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}
