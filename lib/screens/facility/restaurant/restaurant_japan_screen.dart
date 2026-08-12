import 'package:flutter/material.dart';

import '../widgets/facility_place_list.dart';

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
      body: FacilityPlaceList(
        sections: groupedRestaurants.entries.map((entry) {
          final areaName = entry.key;
          final restaurants = entry.value;
          return FacilitySection(
            title: areaName,
            children: restaurants.map((restaurant) {
              final String itemKey =
                  'restaurant-${restaurant['name']}|${restaurant['menu']}|${restaurant['location']}';
              final bool isFavorited = widget.favorites.any(
                (f) => f.startsWith('restaurant-${restaurant['name']}|'),
              );

              return FacilityPlaceCard(
                name: restaurant['name'] as String,
                menu: restaurant['menu'] as String,
                location: restaurant['location'] as String,
                isFavorited: isFavorited,
                onFavoriteToggle: () => widget.toggleFavorite(itemKey),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
