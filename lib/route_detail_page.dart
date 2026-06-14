import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteDetailPage extends StatefulWidget {
  final Map row;

  const RouteDetailPage({super.key, required this.row});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> details = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  String formatTime(String? t) {
    if (t == null) return "";
    return t.substring(0, 5);
  }

  Future<void> fetchDetail() async {
    final row = widget.row;
    final type = row['route_type'];

    // ① 直通（direct / direct_stopover）
    if (type == "direct" || type == "direct_stopover") {
      final res = await supabase
          .from('trips_adjacent')
          .select(
              'seq::int, depart_station, arrive_station, depart_time, arrive_time, vehicle')
          .eq('vehicle', row['vehicle'])
          .gte('seq', row['start_seq'])
          .lte('seq', row['end_seq'])
          .order('seq', ascending: true);

      setState(() {
        details = res;
        loading = false;
      });
      return;
    }

    // ② 乗換（transfer / detour / midday）
    final vehicles = (row['vehicle'] as String).split("→");
    final firstVehicle = vehicles[0];
    final secondVehicle = vehicles[1];

    final firstStartSeq = row['first_start_seq'];
    final firstEndSeq = row['first_end_seq'];
    final secondStartSeq = row['second_start_seq'];
    final secondEndSeq = row['second_end_seq'];

    final firstLeg = await supabase
        .from('trips_adjacent')
        .select(
            'seq::int, depart_station, arrive_station, depart_time, arrive_time, vehicle')
        .eq('vehicle', firstVehicle)
        .gte('seq', firstStartSeq)
        .lte('seq', firstEndSeq)
        .order('seq', ascending: true);

    final secondLeg = await supabase
        .from('trips_adjacent')
        .select(
            'seq::int, depart_station, arrive_station, depart_time, arrive_time, vehicle')
        .eq('vehicle', secondVehicle)
        .gte('seq', secondStartSeq)
        .lte('seq', secondEndSeq)
        .order('seq', ascending: true);

    setState(() {
      details = [
        ...firstLeg.map((e) => {...e, 'leg': 1}),
        ...secondLeg.map((e) => {...e, 'leg': 2}),
      ];
      loading = false;
    });
  }

  String bgImage(String vehicle) {
    if (vehicle.contains("舞")) {
      return "assets/images/maichan.jpg";
    } else {
      return "assets/images/sachichan.jpg";
    }
  }

  String middleLabel(String routeType) {
    switch (routeType) {
      case "midday":
        return "昼休憩後出発（同一車両）";
      case "detour":
        return "他コース周回後出発（同一車両）";
      case "transfer":
      default:
        return "乗換";
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${row['depart_station']} → ${row['arrive_station']}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(row),
    );
  }

  Widget _buildBody(Map row) {
    final type = row['route_type'];

    // ① 直通
    if (type == "direct" || type == "direct_stopover") {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage(row['vehicle'])),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.7),
              BlendMode.srcATop,
            ),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: _buildDirectStations(details),
        ),
      );
    }

    // ② 乗換
    final vehicles = (row['vehicle'] as String).split("→");
    final firstVehicle = vehicles[0];
    final secondVehicle = vehicles[1];

    final firstLeg = details
        .where((d) => d['leg'] == 1)
        .toList()
      ..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));

    final secondLeg = details
        .where((d) => d['leg'] == 2)
        .toList()
      ..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // 前半便
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(bgImage(firstVehicle)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.7),
                      BlendMode.srcATop,
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children:
                      _buildTransferStations(firstLeg, isFirstLeg: true),
                ),
              ),

              // 乗換ラベル
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swap_horiz,
                        size: 28, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      middleLabel(type),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 後半便
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(bgImage(secondVehicle)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.7),
                      BlendMode.srcATop,
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children:
                      _buildTransferStations(secondLeg, isFirstLeg: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 直通・停留あり直通（完全修正版）
  List<Widget> _buildDirectStations(List edges) {
    if (edges.isEmpty) return [];

    final List<Map<String, dynamic>> items = [];

    final first = edges.first;
    items.add({
      'station': first['depart_station'],
      'time': first['depart_time'],
      'label': '発',
      'isStopover': false,
    });

    bool afterStopover = false;
    int i = 0;

    while (i < edges.length) {
      final e = edges[i];

      // ★ 停留開始（学園通り駅→学園通り駅）
      if (e['depart_station'] == '学園通り駅' &&
          e['arrive_station'] == '学園通り駅') {
        // 停留前の「学園通り駅 発」を削除
        if (items.isNotEmpty) {
          final last = items.last;
          if (last['station'] == '学園通り駅' && last['label'] == '発') {
            items.removeLast();
          }
        }

        items.add({
          'station': '学園通り駅',
          'time': e['depart_time'],
          'label': '停留開始',
          'isStopover': true,
        });

        afterStopover = true;
        i++;
        continue;
      }

      final isLast = (i == edges.length - 1);

      // ★ 停留終了直後の「学園通り駅 発」
      if (afterStopover && e['depart_station'] == '学園通り駅') {
        items.add({
          'station': '学園通り駅',
          'time': e['depart_time'],
          'label': '発',
          'isStopover': false,
        });
        afterStopover = false;
        // ← continue しない。到着駅も追加するために fall-through する
      }

      // ★ 通常の到着駅追加（停留後1つ目の駅もここで必ず追加される）
      items.add({
        'station': e['arrive_station'],
        'time': e['arrive_time'],
        'label': isLast ? '着' : '発',
        'isStopover': false,
      });

      i++;
    }

    return List.generate(items.length, (idx) {
      final d = items[idx];
      return _stationRow(
        station: d['station'],
        time: d['time'],
        label: d['label'],
        isFirst: idx == 0,
        isLast: idx == items.length - 1,
        isStopover: d['isStopover'],
      );
    });
  }

  /// 乗換 / 昼休み / 遠回り
  List<Widget> _buildTransferStations(List edges,
      {required bool isFirstLeg}) {
    if (edges.isEmpty) return [];

    final filtered = edges.where((e) {
      final dep = e['depart_station'];
      final arr = e['arrive_station'];
      return !(dep == '学園通り駅' && arr == '学園通り駅');
    }).toList();

    if (filtered.isEmpty) return [];

    final List<Map<String, dynamic>> items = [];

    final first = filtered.first;
    items.add({
      'station': first['depart_station'],
      'time': first['depart_time'],
      'label': '発',
      'isStopover': false,
    });

    for (var i = 0; i < filtered.length; i++) {
      final e = filtered[i];
      final isLast = (i == filtered.length - 1);
      items.add({
        'station': e['arrive_station'],
        'time': e['arrive_time'],
        'label': isLast ? '着' : '発',
        'isStopover': false,
      });
    }

    return List.generate(items.length, (idx) {
      final d = items[idx];
      return _stationRow(
        station: d['station'],
        time: d['time'],
        label: d['label'],
        isFirst: idx == 0,
        isLast: idx == items.length - 1,
        isStopover: d['isStopover'],
      );
    });
  }

  /// タイムライン行
  Widget _stationRow({
    required String station,
    required String time,
    required String label,
    required bool isFirst,
    required bool isLast,
    required bool isStopover,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isStopover ? const Color(0xFFFFF7CC) : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 56,
            child: Stack(
              children: [
                if (!isFirst)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(width: 2, height: 28, color: Colors.black),
                  ),
                if (!isLast)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(width: 2, height: 28, color: Colors.black),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      station,
                      softWrap: true,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "${formatTime(time)}$label",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (isStopover)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.local_parking,
                            color: Colors.orange,
                            size: 26,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
