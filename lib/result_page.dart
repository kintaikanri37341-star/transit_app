import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'route_detail_page.dart';

class ResultPage extends StatefulWidget {
  final String depart;
  final String arrive;

  const ResultPage({
    super.key,
    required this.depart,
    required this.arrive,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    final res = await supabase.rpc(
      'search_trips',
      params: {
        'depart': widget.depart,
        'arrive': widget.arrive,
      },
    );

    setState(() {
      results = res;
      loading = false;
    });
  }

  String formatTime(String? t) {
    if (t == null) return "";
    return t.substring(0, 5);
  }

  String bgImage(String vehicle) {
    if (vehicle.contains("舞")) {
      return "assets/images/maichan.jpg";
    } else {
      return "assets/images/sachichan.jpg";
    }
  }

  // ★ 車両ごとの枠線色
  Color vehicleBorderColor(String vehicle) {
    if (vehicle.contains("舞")) return const Color(0xFFC62828); // 濃い赤
    return const Color(0xFF1565C0); // 濃い青
  }

  // ★ route_type → 表示ラベル
  String routeLabel(String routeType, String vehicle) {
    switch (routeType) {
      case "direct":
        return "直通（$vehicle）";
      case "direct_stopover":
        return "直通（停留あり・$vehicle）";
      case "midday":
        return "昼休憩後出発（同一車両）";
      case "detour":
        return "他コース周回後出発（同一車両）";
      case "transfer":
      default:
        return "乗換";
    }
  }

  // ★ middleLabel（2レグの真ん中に表示するラベル）
  String middleLabel(String routeType) {
    switch (routeType) {
      case "midday":
        return "昼休憩後出発\n（同一車両）";
      case "detour":
        return "他コース周回後出発\n（同一車両）";
      case "transfer":
      default:
        return "乗換";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ★ 背景を完全な白に
      appBar: AppBar(
        title: Text("${widget.depart} → ${widget.arrive}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final row = results[index];
                final routeType = row['route_type'] as String;
                final vehicle = row['vehicle'] as String;

                final isDirectType =
                    routeType == "direct" || routeType == "direct_stopover";

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteDetailPage(row: row),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24), // ★ カード間隔 1.5倍
                    child: isDirectType
                        ? _buildDirectCard(row, vehicle, routeType)
                        : _buildMultiLegCard(row, vehicle, routeType),
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // ★ 直通（停留あり含む）カード：車両色の枠線（赤 or 青）
  // ============================================================
  Widget _buildDirectCard(Map row, String vehicle, String routeType) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: vehicleBorderColor(vehicle),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white, // ★ 背景を真っ白に
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${formatTime(row['depart_time'])} → ${formatTime(row['arrive_time'])}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                routeLabel(routeType, vehicle),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              if (routeType == "direct_stopover")
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
    );
  }

  // ============================================================
  // ★ 乗換カード：黒枠なし → 前半便・後半便の枠線をカード全体に拡張
  // ============================================================
  Widget _buildMultiLegCard(Map row, String vehicle, String routeType) {
    final parts = vehicle.split("→");
    final firstVehicle = parts[0];
    final secondVehicle = parts[1];

    return Column(
      children: [
        // ★ 前半便（赤 or 青枠）カード全体に広げる
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: vehicleBorderColor(firstVehicle),
              width: 3,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${formatTime(row['depart_time'])} → ${formatTime(row['first_arrive_time'])}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                firstVehicle,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),

        // ★ 中央の乗換ラベル（白背景）
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              const Icon(Icons.swap_horiz, size: 28, color: Colors.black),
              const SizedBox(height: 4),
              Text(
                middleLabel(routeType),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // ★ 後半便（赤 or 青枠）カード全体に広げる
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: vehicleBorderColor(secondVehicle),
              width: 3,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${formatTime(row['second_depart_time'])} → ${formatTime(row['arrive_time'])}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                secondVehicle,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
