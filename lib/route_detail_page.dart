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
          ),
          child: Column(
            children: _buildTransferStations(firstLeg, isFirstLeg: true),
          ),
        ),

        // 中央ラベル
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              middleLabel(type),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          ),
          child: Column(
            children: _buildTransferStations(secondLeg, isFirstLeg: false),
          ),
        ),
      ],
    );
  }

  /// 直通・停留あり直通
  List<Widget> _buildDirectStations(List edges) {
    if (edges.isEmpty) return [];

    // まず「行データ」を組み立てる
    final List<Map<String, String>> items = [];

    final first = edges.first;
    items.add({
      'station': first['depart_station'] as String,
      'time': first['depart_time'] as String,
      'label': '発',
    });

    bool afterStopover = false;
    int i = 0;
    while (i < edges.length) {
      final e = edges[i];

      if (e['depart_station'] == '学園通り駅' &&
          e['arrive_station'] == '学園通り駅') {
        items.add({
          'station': '学園通り駅',
          'time': e['depart_time'] as String,
          'label': '停留開始',
        });
        afterStopover = true;
        i += 1;
        continue;
      }

      if (afterStopover && e['depart_station'] == '学園通り駅') {
        items.add({
          'station': '学園通り駅',
          'time': e['depart_time'] as String,
          'label': '発',
        });
        afterStopover = false;
      }

      final isLastEdge = (i == edges.length - 1);
      items.add({
        'station': e['arrive_station'] as String,
        'time': e['arrive_time'] as String,
        'label': isLastEdge ? '着' : '発',
      });

      i += 1;
    }

    // 行データから、isFirst / isLast を付けて描画
    final List<Widget> rows = [];
    for (var idx = 0; idx < items.length; idx++) {
      final d = items[idx];
      rows.add(_stationRow(
        station: d['station']!,
        time: d['time']!,
        label: d['label']!,
        isFirst: idx == 0,
        isLast: idx == items.length - 1,
      ));
    }
    return rows;
  }

  /// 乗換 / 昼休み / 遠回り
  List<Widget> _buildTransferStations(List edges, {required bool isFirstLeg}) {
    if (edges.isEmpty) return [];

    final filtered = isFirstLeg
        ? edges.where((e) {
            final dep = e['depart_station'];
            final arr = e['arrive_station'];
            return !(dep == '学園通り駅' && arr == '学園通り駅');
          }).toList()
        : edges;

    if (filtered.isEmpty) return [];

    final List<Map<String, String>> items = [];

    final first = filtered.first;
    items.add({
      'station': first['depart_station'] as String,
      'time': first['depart_time'] as String,
      'label': '発',
    });

    for (var i = 0; i < filtered.length; i++) {
      final e = filtered[i];
      final isLastEdge = (i == filtered.length - 1);
      items.add({
        'station': e['arrive_station'] as String,
        'time': e['arrive_time'] as String,
        'label': isLastEdge ? '着' : '発',
      });
    }

    final List<Widget> rows = [];
    for (var idx = 0; idx < items.length; idx++) {
      final d = items[idx];
      rows.add(_stationRow(
        station: d['station']!,
        time: d['time']!,
        label: d['label']!,
        isFirst: idx == 0,
        isLast: idx == items.length - 1,
      ));
    }
    return rows;
  }

  /// タイムライン風：左に黒い縦線＋白丸
  Widget _stationRow({
    required String station,
    required String time,
    required String label,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側の縦線＋白丸
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                // 上方向の線（出発行には描かない）
                if (!isFirst)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: Colors.black,
                    ),
                  ),
                // 下方向の線（到着行には描かない）
                if (!isLast)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: Colors.black,
                    ),
                  ),
                // 白丸
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 16,
                    height: 16,
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

          // 駅名＋時刻（駅名は長いときだけ自動縮小）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  // 駅名：左寄せで、必要なときだけ縮小して全体表示
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        station,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 時刻：右側に固定、絶対に潰れない
                  Text(
                    "${formatTime(time)}$label",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
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
