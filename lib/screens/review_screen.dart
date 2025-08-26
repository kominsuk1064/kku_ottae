import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyReviews = [
      {
        'place': '메가MGC커피 충주건국대점',
        'content': '분위기 좋고 넓어요!',
        'date': '2025.07.05',
      },
      {
        'place': '컴포즈커피 건국대점',
        'content': '조용해서 공부하기 좋아요.',
        'date': '2025.07.03',
      },
      {'place': '짱돌 충주건대점', 'content': '해물파닭 맛집입니다.', 'date': '2025.07.01'},
    ];

    return Scaffold(
      backgroundColor: Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('내가 쓴 후기'),
        backgroundColor: Color(0xFF00552E),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: dummyReviews.length,
        itemBuilder: (context, index) {
          final review = dummyReviews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                review['place'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(review['content'] ?? ''),
                  const SizedBox(height: 4),
                  Text(
                    review['date'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: const Icon(Icons.edit_note),
              onTap: () {
                // TODO: 후기 수정 화면 연결 시 사용
              },
            ),
          );
        },
      ),
    );
  }
}
