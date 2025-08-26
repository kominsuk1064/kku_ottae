import 'package:flutter/material.dart';

class ExBusInfoScreen extends StatefulWidget {
  final Set<String> favorites;
  const ExBusInfoScreen({super.key, required this.favorites});

  @override
  State<ExBusInfoScreen> createState() => _ExBusInfoScreenState();
}

class _ExBusInfoScreenState extends State<ExBusInfoScreen> {
  final List<String> dongseoul = [
    "7:00",
    "9:00",
    "9:50",
    "10:20",
    "10:45",
    "13:00",
    "13:35",
    "14:15",
    "14:35",
    "15:00",
    "16:40",
    "18:20",
    "19:20",
    "20:10",
  ];
  final List<String> anyang = [
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "16:25",
    "",
    "",
    "",
    "",
  ];
  final List<String> ansan = [
    "8:30",
    "",
    "",
    "13:20",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "17:30",
  ];

  final Set<String> directDongSeoul = {
    "9:50",
    "10:45",
    "13:35",
    "14:15",
    "14:35",
    "18:20",
    "19:20",
  };

  void toggleFavorite(String key) {
    setState(() {
      if (widget.favorites.contains(key)) {
        widget.favorites.remove(key);
      } else {
        widget.favorites.add(key);
      }
    });
  }

  Widget buildCell(String time, String key, {bool isDongSeoul = false}) {
    final isDirect = isDongSeoul && directDongSeoul.contains(time);
    final textColor = isDirect ? Colors.red : Colors.black;
    final label = isDirect ? "$time(직통)" : time;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
          ),
          if (time.isNotEmpty)
            IconButton(
              iconSize: 18,
              padding: const EdgeInsets.only(left: 4),
              constraints: const BoxConstraints(),
              icon: Icon(
                widget.favorites.contains(key) ? Icons.star : Icons.star_border,
                color: widget.favorites.contains(key)
                    ? Colors.amber
                    : Colors.grey,
              ),
              onPressed: () => toggleFavorite(key),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('건국터미널 시외버스 시간표'),
        backgroundColor: Color(0xFF00552E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Column(
            children: [
              Row(
                children: const [
                  Expanded(
                    child: Center(
                      child: Text(
                        '동서울',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '안양·부천',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '안산·인천',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: dongseoul.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          buildCell(
                            dongseoul[index],
                            'dong-${dongseoul[index]}',
                            isDongSeoul: true,
                          ),
                          buildCell(
                            anyang[index],
                            'anyang-${anyang[index]}-$index',
                          ),
                          buildCell(
                            ansan[index],
                            'ansan-${ansan[index]}-$index',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
