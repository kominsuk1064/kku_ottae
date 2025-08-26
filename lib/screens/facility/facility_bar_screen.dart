import 'package:flutter/material.dart';

class FacilityBarScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const FacilityBarScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<FacilityBarScreen> createState() => _FacilityBarScreenState();
}

class _FacilityBarScreenState extends State<FacilityBarScreen> {
  final Map<String, List<Map<String, String>>> groupedBars = const {
    '신촌 · 단월': [
      {'name': '여명포차', 'menu': '요리주점', 'location': '충북 충주시 충열4길 5-3'},
      {'name': '전국 팔도', 'menu': '요리주점', 'location': '충북 충주시 충열4길 5'},
      {'name': '바깥', 'menu': '요리주점', 'location': '충북 충주시 충열5길 20'},
      {'name': 'Appro', 'menu': '퓨전음식', 'location': '충북 충주시 충열1길 28 1층'},
      {'name': '풀빵', 'menu': '분식', 'location': '충북 충주시 충열5길 19'},
      {'name': '건국이네포차', 'menu': '고기', 'location': '충북 충주시 충열5길 24 104호'},
      {'name': '게이트원', 'menu': '요리주점', 'location': '충북 충주시 충열2길 19 1층'},
      {'name': '매드슬로우', 'menu': '바, 칵테일', 'location': '충북 충주시 충열4길 18 지하'},
      {'name': '사이', 'menu': '이자카야', 'location': '충북 충주시 충열5길 16'},
      {'name': '지포차', 'menu': '요리주점', 'location': '충북 충주시 충열5길 32'},
      {'name': '단월정(구 한스포차)', 'menu': '요리주점', 'location': '충북 충주시 충열5길 30 2층'},
      {'name': '밤, 새벽', 'menu': '요리주점', 'location': '충북 충주시 충열1길 20-9 2층'},
      {'name': '깡통고무신', 'menu': '요리주점', 'location': '충북 충주시 충열1길 20-7 1층'},
      {'name': '돈사랑포차', 'menu': '고기', 'location': '충북 충주시 단월동 484'},
      {'name': '치카야', 'menu': '이자카야', 'location': '충북 충주시 충열1길 20-2 지하'},
      {'name': '주방', 'menu': '요리주점(룸술집)', 'location': '충북 충주시 충열1길 21'},
      {'name': '짱돌', 'menu': '치킨', 'location': '충북 충주시 충열1길 17'},
      {'name': '레일로드', 'menu': '요리주점', 'location': '충북 충주시 충열5길 15-2'},
      {
        'name': '땡초우동in포차',
        'menu': '우동',
        'location': '충북 충주시 충열5길 21 1층 땡초우동in포차',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('술집', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: groupedBars.entries.map((entry) {
          final areaName = entry.key;
          final bars = entry.value;
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
              ...bars.map((bar) {
                final String itemKey =
                    'restaurant-${bar['name']}|${bar['menu']}|${bar['location']}';
                final bool isFavorited = widget.favorites.any(
                  (f) => f.startsWith('restaurant-${bar['name']}|'),
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
                              bar['name']!,
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
                        Text('메뉴: ${bar['menu']}'),
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
                              bar['location']!,
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
