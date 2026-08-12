import 'package:flutter/material.dart';

import '../widgets/facility_place_list.dart';

class RestaurantKoreaScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const RestaurantKoreaScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<RestaurantKoreaScreen> createState() => _RestaurantKoreaScreenState();
}

class _RestaurantKoreaScreenState extends State<RestaurantKoreaScreen> {
  final Map<String, List<Map<String, dynamic>>> groupedRestaurants = const {
    '신촌 · 단월': [
      {'name': '엄마손분식', 'menu': '분식류, 한식', 'location': '충북 충주시 충열5길 13'},
      {'name': '대박분식', 'menu': '분식류, 한식', 'location': '충북 충주시 충열5길 23'},
      {'name': '건국이네밥집', 'menu': '백반', 'location': '충북 충주시 충열5길 24 104호'},
      {'name': '지뎅', 'menu': '덮밥', 'location': '충북 충주시 충열5길 22'},
      {'name': '단월 뚝배기', 'menu': '국밥', 'location': '충북 충주시 하단1길 10 단월 뚝배기'},
      {'name': '돈사랑포차', 'menu': '고기', 'location': '충북 충주시 단월동 484'},
      {'name': '건대이모네순대국', 'menu': '국밥', 'location': '충북 충주시 충열4길 9-2'},
      {'name': '오뚜기 부대찌개', 'menu': '부대찌개', 'location': '충북 충주시 충열1길 16'},
      {'name': '한샘식당', 'menu': '한식', 'location': '충북 충주시 충열1길 20-4'},
      {'name': '안성가마솥순대국', 'menu': '국밥', 'location': '충북 충주시 하단1길 21'},
      {'name': '꼬꼬야', 'menu': '닭갈비', 'location': '충북 충주시 충열4길 5-1'},
      {'name': '큰집막창', 'menu': '곱창, 막창', 'location': '충북 충주시 충열5길 15-1'},
    ],
    '모시래 마을': [
      {'name': '분식나라', 'menu': '분식류, 한식', 'location': '충북 충주시 모시래2길 38'},
      {'name': '쭈꾸대장', 'menu': '쭈꾸미 볶음', 'location': '충북 충주시 모시래1길 19'},
      {'name': '함지박', 'menu': '백숙, 오리', 'location': '충북 충주시 모시래2길 7'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('한식', style: TextStyle(color: Colors.white)),
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
