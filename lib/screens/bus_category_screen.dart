import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kku_ottae/features/bus/application/bus_arrivals_controller.dart';
import 'package:kku_ottae/features/bus/application/bus_arrivals_state.dart';
import 'package:kku_ottae/features/bus/domain/bus_arrival.dart';
import 'package:kku_ottae/features/bus/domain/bus_arrival_repository.dart';
import 'package:kku_ottae/features/bus/domain/bus_route_summary.dart';
import 'package:kku_ottae/features/bus/domain/bus_stop.dart';
import 'package:kku_ottae/features/favorites/presentation/favorites_builder.dart';

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
            const InCityBusTab(),
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
  const InCityBusTab({super.key});

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
    const fixedStops = <BusStop>[
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
                builder: (_) => FavoritesBuilder(
                  builder: (context, favorites, toggleFavorite) =>
                      BusArrivalsScreen(
                        stop: s,
                        favorites: favorites,
                        toggleFavorite: toggleFavorite,
                        tagoKeyEncoded: _tagoKeyEncoded,
                        cityCode: _cityCode,
                      ),
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
   도착 정보 화면
   ========================== */

class BusArrivalsScreen extends ConsumerWidget {
  final BusStop stop;
  final Set<String> favorites;
  final void Function(String) toggleFavorite;
  final String tagoKeyEncoded;
  final String cityCode;
  final BusArrivalRepository? repository;

  const BusArrivalsScreen({
    super.key,
    required this.stop,
    required this.favorites,
    required this.toggleFavorite,
    required this.tagoKeyEncoded,
    required this.cityCode,
    this.repository,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = BusArrivalsRequest(
      stopId: stop.stopId,
      serviceKey: tagoKeyEncoded,
      cityCode: cityCode,
      repository: repository,
    );
    final provider = busArrivalsControllerProvider(request);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('${stop.stopName} · 실시간'),
        backgroundColor: const Color(0xFF00552E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                state.status == BusArrivalsStatus.loading || state.isRefreshing
                ? null
                : () => controller.refresh(),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _lastUpdatedLabel(state.lastUpdated!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          SizedBox(
            height: 2,
            child: state.isRefreshing
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
          Expanded(
            child: switch (state.status) {
              BusArrivalsStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              BusArrivalsStatus.error => _BusArrivalsError(
                message: state.errorMessage ?? '버스 정보를 불러오지 못했습니다.',
                onRetry: () => controller.retry(),
              ),
              BusArrivalsStatus.empty => _EmptyWithRoutes(routes: state.routes),
              BusArrivalsStatus.success => _ArrivalsList(
                arrivals: state.arrivals,
                favorites: favorites,
                toggleFavorite: toggleFavorite,
              ),
            },
          ),
        ],
      ),
    );
  }

  String _lastUpdatedLabel(DateTime lastUpdated) {
    final hour = lastUpdated.hour.toString().padLeft(2, '0');
    final minute = lastUpdated.minute.toString().padLeft(2, '0');
    return '마지막 갱신: $hour:$minute';
  }
}

class _ArrivalsList extends StatelessWidget {
  const _ArrivalsList({
    required this.arrivals,
    required this.favorites,
    required this.toggleFavorite,
  });

  final List<BusArrival> arrivals;
  final Set<String> favorites;
  final void Function(String) toggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: arrivals.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final arrival = arrivals[index];
        final favoriteKey = 'busroute:${arrival.routeId}';
        final isFavorite = favorites.contains(favoriteKey);

        return ListTile(
          leading: const Icon(Icons.directions_bus),
          title: Text(
            '${_etaMinutesLine(arrival)} · ${arrival.routeName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${_etaStopsLine(arrival)} · ${arrival.direction}'),
          trailing: IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border),
            color: isFavorite ? Colors.amber : Colors.grey,
            onPressed: () => toggleFavorite(favoriteKey),
          ),
        );
      },
    );
  }

  String _etaMinutesLine(BusArrival arrival) {
    final minutes = max(0, arrival.minutes);
    return minutes == 0 ? '곧 도착' : '약 $minutes분 후';
  }

  String _etaStopsLine(BusArrival arrival) {
    return arrival.stopsAway > 0 ? '${arrival.stopsAway}정류장 전' : '바로 앞';
  }
}

class _BusArrivalsError extends StatelessWidget {
  const _BusArrivalsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWithRoutes extends StatelessWidget {
  const _EmptyWithRoutes({required this.routes});

  final List<BusRouteSummary> routes;

  @override
  Widget build(BuildContext context) {
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
                    .map((route) => Chip(label: Text(route.routeName)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
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
