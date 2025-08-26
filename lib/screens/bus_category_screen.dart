import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/* ==========================
   BusCategoryScreen
   시외버스: 기존 더미 + 즐겨찾기(변경 없음)
   시내버스: 고정 정류장 6개 + 실시간 도착
   ========================== */

class BusCategoryScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const BusCategoryScreen({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  State<BusCategoryScreen> createState() => _BusCategoryScreenState();
}

class _BusCategoryScreenState extends State<BusCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00552E),
      appBar: AppBar(
        title: const Text('버스 정보', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00552E),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '시외버스'),
            Tab(text: '시내버스'),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            OutCityBusTab(
              favorites: widget.favorites,
              toggleFavorite: widget.toggleFavorite,
            ),
            InCityBusTab(
              favorites: widget.favorites,
              toggleFavorite: widget.toggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================
   시내버스 탭: 고정 정류장 6개
   ========================== */

class InCityBusTab extends StatelessWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const InCityBusTab({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  String get _cityCode =>
      const String.fromEnvironment('CITY_CODE', defaultValue: '33020');

  String get _tagoKeyRaw =>
      const String.fromEnvironment('TAGO_KEY', defaultValue: '');

  String get _tagoKeyEncoded => _tagoKeyRaw.contains('%')
      ? _tagoKeyRaw
      : Uri.encodeComponent(_tagoKeyRaw);

  @override
  Widget build(BuildContext context) {
    // 확정된 6개 정류장
    final fixedStops = <BusStop>[
      // 정문
      BusStop(stopId: 'CHB272060002', stopName: '건국대(정문·시외방향)'),
      BusStop(stopId: 'CHB272064033', stopName: '건국대(정문·시내방향)'),
      // 후문
      BusStop(stopId: 'CHB272060006', stopName: '건국대학교(후문·시외방향)'),
      BusStop(stopId: 'CHB272060007', stopName: '건국대학교(후문·시내방향)'),
      // KU스테이션
      BusStop(stopId: 'CHB272064512', stopName: 'KU스테이션(충주역, 버스터미널 방향)'),
      BusStop(stopId: 'CHB272064513', stopName: 'KU스테이션(건국대학교 후문, 시내 방향)'),
    ];

    if (_tagoKeyRaw.isEmpty) {
      return const Center(
        child: Text(
          'TAGO_KEY가 없습니다. 실행 인자에 --dart-define=TAGO_KEY=... 를 넣어주세요.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: fixedStops.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = fixedStops[i];
        return ListTile(
          leading: const Icon(Icons.place),
          title: Text(
            s.stopName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('ID: ${s.stopId}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BusArrivalsScreen(
                  stop: s,
                  favorites: favorites,
                  toggleFavorite: toggleFavorite,
                  tagoKeyEncoded: _tagoKeyEncoded,
                  cityCode: _cityCode,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* ==========================
   모델
   ========================== */

class BusStop {
  final String stopId;
  final String stopName;
  final double? lat;
  final double? lng;
  BusStop({required this.stopId, required this.stopName, this.lat, this.lng});
}

class BusArrivalItem {
  final String routeId; // routeid
  final String routeName; // routeno
  final int minutes; // arrtime(초) -> 분
  final int stopsAway; // arrprevstationcnt
  final String direction; // 0:상행, 1:하행

  BusArrivalItem({
    required this.routeId,
    required this.routeName,
    required this.minutes,
    required this.stopsAway,
    required this.direction,
  });

  factory BusArrivalItem.fromTagoJson(Map<String, dynamic> j) {
    final sec = int.tryParse('${j['arrtime'] ?? '0'}') ?? 0;
    final mins = (sec / 60).ceil();
    final prev = int.tryParse('${j['arrprevstationcnt'] ?? '0'}') ?? 0;
    final up = '${j['updown'] ?? ''}';
    return BusArrivalItem(
      routeId: '${j['routeid'] ?? ''}',
      routeName: '${j['routeno'] ?? ''}',
      minutes: mins,
      stopsAway: prev,
      direction: up == '0' ? '상행' : '하행',
    );
  }
}

/* ==========================
   도착 정보 화면
   ========================== */

class BusArrivalsScreen extends StatefulWidget {
  final BusStop stop;
  final Set<String> favorites;
  final void Function(String) toggleFavorite;
  final String tagoKeyEncoded;
  final String cityCode;

  const BusArrivalsScreen({
    super.key,
    required this.stop,
    required this.favorites,
    required this.toggleFavorite,
    required this.tagoKeyEncoded,
    required this.cityCode,
  });

  @override
  State<BusArrivalsScreen> createState() => _BusArrivalsScreenState();
}

class _BusArrivalsScreenState extends State<BusArrivalsScreen> {
  bool _loading = false;
  String? _error;
  List<BusArrivalItem> _arrivals = [];
  Timer? _poller;
  DateTime? _lastUpdated;

  // ▼▼ 전역 오프셋 보정값 ▼▼
  static const int globalMinBias = 2; // 전체에서 -3분
  static const int globalStopsBias = 1; // 전체에서 -2정류장

  @override
  void initState() {
    super.initState();
    _fetchArrivals();
    _poller = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchArrivals(),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  BusArrivalItem _applyBias(BusArrivalItem a) {
    final adjMin = (a.minutes - globalMinBias).clamp(0, 9999);
    final adjStops = (a.stopsAway - globalStopsBias).clamp(0, 9999);
    return BusArrivalItem(
      routeId: a.routeId,
      routeName: a.routeName,
      minutes: adjMin,
      stopsAway: adjStops,
      direction: a.direction,
    );
  }

  String _etaMinutesLine(BusArrivalItem a) {
    final m = max(0, a.minutes);
    if (m == 0) return '곧 도착';
    return '약 ${m}분 후';
  }

  String _etaStopsLine(BusArrivalItem a) {
    return a.stopsAway > 0 ? '${a.stopsAway}정류장 전' : '바로 앞';
  }

  Future<void> _fetchArrivals() async {
    setState(() {
      _loading = true;
      _error = null;
      _arrivals = [];
    });

    try {
      final uri = Uri.parse(
        'https://apis.data.go.kr/1613000/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList'
        '?serviceKey=${widget.tagoKeyEncoded}&_type=json'
        '&cityCode=${widget.cityCode}&nodeId=${Uri.encodeComponent(widget.stop.stopId)}'
        '&pageNo=1&numOfRows=30',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        setState(() => _error = 'HTTP ${res.statusCode}');
        return;
      }

      final text = res.body.trim();

      // XML 오류 응답
      if (text.startsWith('<')) {
        final isPolicy = text.contains('Policy Falsified');
        final msg = isPolicy ? 'API 거부: 키/엔드포인트/파라미터 확인' : 'API XML 오류 응답';
        setState(() => _error = msg);
        return;
      }

      // JSON 파싱
      final body = jsonDecode(text);

      // totalCount=0 → 정상 빈 결과
      final total = body?['response']?['body']?['totalCount'];
      if (total is int && total == 0) {
        setState(() {
          _arrivals = const [];
          _error = null;
        });
        return;
      }

      // item 변형 대응
      final items = _asList(body);

      final parsed = items
          .whereType<Map<String, dynamic>>()
          .map((e) => BusArrivalItem.fromTagoJson(e))
          .map(_applyBias) // ◀ 보정 적용
          .toList();

      // 정렬: 분 → 정류장수 → 노선명
      parsed.sort((a, b) {
        final c1 = a.minutes.compareTo(b.minutes);
        if (c1 != 0) return c1;
        final c2 = a.stopsAway.compareTo(b.stopsAway);
        if (c2 != 0) return c2;
        return a.routeName.compareTo(b.routeName);
      });

      setState(() {
        _arrivals = parsed;
        _error = null;
      });
    } on TimeoutException {
      setState(() => _error = '요청 시간 초과');
    } catch (_) {
      setState(() => _error = '응답 파싱 실패');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    }
  }

  List<dynamic> _asList(dynamic body) {
    if (body is List) return body;
    if (body is Map && body['response'] != null) {
      final items = body['response']?['body']?['items']?['item'];
      if (items == null) return <dynamic>[];
      if (items is List) return items;
      if (items is Map) return [items];
      return <dynamic>[];
    }
    return <dynamic>[];
  }

  Future<List<Map<String, dynamic>>> _fetchRoutesThroughStop() async {
    final uri = Uri.parse(
      'https://apis.data.go.kr/1613000/BusRouteInfoInqireService/getSttnThrghRouteList'
      '?serviceKey=${widget.tagoKeyEncoded}&_type=json'
      '&cityCode=${widget.cityCode}&nodeid=${Uri.encodeComponent(widget.stop.stopId)}'
      '&pageNo=1&numOfRows=100',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final j = jsonDecode(res.body);
      final items = j['response']?['body']?['items']?['item'];
      if (items == null) return [];
      return items is List
          ? items.cast<Map<String, dynamic>>()
          : [items as Map<String, dynamic>];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    return Scaffold(
      appBar: AppBar(
        title: Text('${stop.stopName} · 실시간'),
        backgroundColor: const Color(0xFF00552E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchArrivals,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_lastUpdated != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '마지막 갱신: ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : (_arrivals.isEmpty)
                ? _EmptyWithRoutes(fetchRoutes: _fetchRoutesThroughStop)
                : ListView.separated(
                    itemCount: _arrivals.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final a = _arrivals[i];
                      final favKey = 'busroute:${a.routeId}';
                      final isFav = widget.favorites.contains(favKey);

                      final line1 = _etaMinutesLine(a); // "약 X분 후" 또는 "곧 도착"
                      final line2 = _etaStopsLine(a); // "N정류장 전" 또는 "바로 앞"

                      return ListTile(
                        leading: const Icon(Icons.directions_bus),
                        // 요청: "몇분 후" 먼저, "몇정류장 전"은 엔터로 분리
                        title: Text(
                          '$line1 · ${a.routeName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('$line2 · ${a.direction}'),
                        trailing: IconButton(
                          icon: Icon(isFav ? Icons.star : Icons.star_border),
                          color: isFav ? Colors.amber : Colors.grey,
                          onPressed: () => widget.toggleFavorite(favKey),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWithRoutes extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> Function() fetchRoutes;
  const _EmptyWithRoutes({required this.fetchRoutes});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchRoutes(),
      builder: (context, snap) {
        final routes = snap.data ?? [];
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  '현재 도착 예정 차량이 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
                if (routes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '지나는 노선',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: routes
                        .map((r) => Chip(label: Text('${r['routeno'] ?? ''}')))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ==========================
   시외버스 탭 (변경 없음)
   ========================== */

class OutCityBusTab extends StatelessWidget {
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  const OutCityBusTab({
    super.key,
    required this.favorites,
    required this.toggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> busTimes = {
      '동서울': [
        '7:00',
        '9:00',
        '9:50',
        '10:20',
        '10:45',
        '13:00',
        '13:35',
        '14:15',
        '14:35',
        '15:00',
        '16:40',
        '18:20',
        '19:20',
        '20:10',
      ],
      '안양·부천': ['16:25'],
      '안산·인천': ['8:30', '13:20', '17:30'],
    };

    final Set<String> directDongSeoul = {
      '9:50',
      '10:45',
      '13:35',
      '14:15',
      '14:35',
      '18:20',
      '19:20',
    };

    return ListView(
      children: busTimes.entries.map((entry) {
        final title = entry.key;
        final times = entry.value;

        return ExpansionTile(
          title: Text(
            '$title행 시외버스',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.green[50],
          collapsedBackgroundColor: Colors.white,
          children: times.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      '시간 정보 없음',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ]
              : times.map((time) {
                  final isDirect =
                      title == '동서울' && directDongSeoul.contains(time);
                  final key = title == '동서울'
                      ? 'dong-$time'
                      : title == '안양·부천'
                      ? 'anyang-$time'
                      : 'ansan-$time';

                  return ListTile(
                    title: Row(
                      children: [
                        Text(
                          isDirect ? '$time (직통)' : time,
                          style: TextStyle(
                            color: isDirect ? Colors.red : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          iconSize: 18,
                          padding: const EdgeInsets.only(left: 4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            favorites.contains(key)
                                ? Icons.star
                                : Icons.star_border,
                            color: favorites.contains(key)
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          onPressed: () => toggleFavorite(key),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        );
      }).toList(),
    );
  }
}
