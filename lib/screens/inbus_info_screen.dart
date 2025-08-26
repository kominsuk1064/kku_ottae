import 'package:flutter/material.dart';

class InBusInfoScreen extends StatelessWidget {
  const InBusInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00552E),
      appBar: AppBar(
        title: const Text("시내버스 정보"),
        backgroundColor: Color(0xFF00552E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 🔍 검색 바
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '버스 번호 또는 정류장 검색',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🚌 정류장 도착 정보 박스 (예시용)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "200 (단월 → 오가리)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "정거장",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "도착 예정 시간",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text("단월"), Text("4분 뒤 도착")],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text("충주 터미널"), Text("9분 뒤 도착")],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 버스 리스트 (예시용)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ListView(
                  children: const [
                    BusListTile(route: "200", desc: "단월 → 오가리"),
                    BusListTile(route: "200", desc: "단월 → 차고지"),
                    BusListTile(route: "200", desc: "상풍 → 오가리"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BusListTile extends StatelessWidget {
  final String route;
  final String desc;

  const BusListTile({super.key, required this.route, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.directions_bus),
        title: Text(
          "$route ($desc)",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
