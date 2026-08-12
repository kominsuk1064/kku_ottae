import 'package:flutter/material.dart';
import 'package:kku_ottae/features/favorites/presentation/favorites_builder.dart';

import 'facility/facility_restaurant_screen.dart';
import 'facility/facility_cafe_screen.dart';
import 'facility/facility_bar_screen.dart';
import 'facility/facility_mart_screen.dart';
import 'facility/facility_etc_screen.dart';
import 'facility/facility_pc_screen.dart';
import 'facility/widgets/facility_category_grid.dart';

class FacilityCategoryScreen extends StatelessWidget {
  const FacilityCategoryScreen({super.key});

  final List<_Category> _categories = const [
    _Category(name: '식당', emoji: '🍽️'),
    _Category(name: '카페', emoji: '☕'),
    _Category(name: '술집', emoji: '🍻'),
    _Category(name: '편의점/마트', emoji: '🛒'),
    _Category(name: '기타 생활시설', emoji: '🛠️'),
    _Category(name: '오락시설', emoji: '🎮'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('편의시설 카테고리', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FacilityCategoryGrid(
        key: const ValueKey('facility-category-grid'),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];

          return FacilityCategoryTile(
            key: ValueKey('facility-category-${category.name}'),
            label: category.name,
            symbol: category.emoji,
            onTap: () {
              // 🔁 카테고리별 분기처리
              switch (category.name) {
                case '식당':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FacilityRestaurantScreen(),
                    ),
                  );
                  break;
                case '카페':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            FacilityCafeScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '술집':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            FacilityBarScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '편의점/마트':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            FacilityMartScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '오락시설':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            FacilityPcScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                case '기타 생활시설':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesBuilder(
                        builder: (context, favorites, toggleFavorite) =>
                            FacilityEtcScreen(
                              favorites: favorites,
                              toggleFavorite: toggleFavorite,
                            ),
                      ),
                    ),
                  );
                  break;
                default:
                  // 혹시 대비
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${category.name} 화면이 없습니다.')),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

class _Category {
  final String name;
  final String emoji;

  const _Category({required this.name, required this.emoji});
}
