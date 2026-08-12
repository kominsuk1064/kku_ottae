import 'package:flutter/material.dart';
import 'package:kku_ottae/features/favorites/presentation/favorites_builder.dart';

import 'restaurant/restaurant_korea_screen.dart';
import 'restaurant/restaurant_china_screen.dart';
import 'restaurant/restaurant_japan_screen.dart';
import 'restaurant/restaurant_chicken_screen.dart';
import 'restaurant/restaurant_meat_screen.dart';
import 'widgets/facility_category_grid.dart';

class _Subcategory {
  final String name;
  final String emoji;

  const _Subcategory({required this.name, required this.emoji});
}

class FacilityRestaurantScreen extends StatelessWidget {
  const FacilityRestaurantScreen({super.key});

  static const List<_Subcategory> _subcategories = [
    _Subcategory(name: '한식', emoji: '🍚'),
    _Subcategory(name: '중식', emoji: '🍜'),
    _Subcategory(name: '일식, 아시안', emoji: '🍱'),
    _Subcategory(name: '치킨·피자·햄버거·토스트', emoji: '🍗'),
    _Subcategory(name: '족발/보쌈/고기/꼬치', emoji: '🍢'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('식당 소분류', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FacilityCategoryGrid(
        key: const ValueKey('restaurant-category-grid'),
        itemCount: _subcategories.length,
        itemBuilder: (context, index) {
          final sub = _subcategories[index];

          return FacilityCategoryTile(
            key: ValueKey('restaurant-category-${sub.name}'),
            label: sub.name,
            symbol: sub.emoji,
            onTap: () {
              switch (sub.name) {
                case '한식':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            RestaurantKoreaScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '중식':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            RestaurantChinaScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '일식, 아시안':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            RestaurantJapanScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '치킨·피자·햄버거·토스트':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            RestaurantChickenScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '족발/보쌈/고기/꼬치':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            RestaurantMeatScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
              }
            },
          );
        },
      ),
    );
  }
}
