import 'package:flutter/material.dart';

class FacilityMartScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const FacilityMartScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<FacilityMartScreen> createState() => _FacilityMartScreenState();
}

class _FacilityMartScreenState extends State<FacilityMartScreen> {
  final Map<String, List<Map<String, String>>> groupedMarts = const {
    '신촌 · 단월': [
      {'name': 'GS25 충주건대학생회관점', 'location': '충북 충주시 충원대로 268(학생회관 지하)'},
      {'name': 'GS25 충주건대점', 'location': '충북 충주시 충열5길 16'},
      {'name': 'CU 건대으뜸점', 'location': '충북 충주시 충열4길 6 (단월동) 1층'},
      {'name': '세븐일레븐 충주건국대카페점', 'location': '충북 충주시 충열1길 20-9'},
      {'name': '이마트24 충주단월건대점', 'location': '충북 충주시 충원대로 206'},
      {'name': 'GS25 충주단월원룸점', 'location': '충북 충주시 하단1길 18'},
      {'name': '베스트마트문구', 'location': '충북 충주시 충열4길 18'},
      {'name': '굿비어아이스크림할인점', 'location': '충북 충주시 충열4길 21 굿편의점'},
    ],
    '모시래 마을': [
      {'name': 'GS25 건대모시래점', 'location': '충북 충주시 모시래1길 33'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('편의점/마트', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: groupedMarts.entries.map((entry) {
          final area = entry.key;
          final marts = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00552E),
                ),
              ),
              const SizedBox(height: 8),
              ...marts.map((store) {
                final itemKey =
                    'restaurant-${store['name']}|편의점/마트|${store['location']}';
                final isFavorited = widget.favorites.any(
                  (f) => f.startsWith('restaurant-${store['name']}|'),
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
                              store['name']!,
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
                              onPressed: () => widget.toggleFavorite(itemKey),
                            ),
                          ],
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
                              store['location']!,
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
