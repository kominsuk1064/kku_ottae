import 'package:flutter/material.dart';
import 'package:kku_ottae/features/favorites/presentation/favorites_builder.dart';

import 'restaurant/restaurant_korea_screen.dart';
import 'restaurant/restaurant_china_screen.dart';
import 'restaurant/restaurant_japan_screen.dart';
import 'restaurant/restaurant_chicken_screen.dart';
import 'restaurant/restaurant_meat_screen.dart';

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
      body: Center(
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: _subcategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 130,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final sub = _subcategories[index];

            return GestureDetector(
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(sub.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 10),
                    Text(
                      sub.name,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
