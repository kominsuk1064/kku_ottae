import 'package:flutter/material.dart';

import '../widgets/facility_place_list.dart';

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
