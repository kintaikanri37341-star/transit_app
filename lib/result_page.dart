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

  // ★ 車両ごとの枠線色（直通カード用）
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
      backgroundColor: Colors.white, // ★ 画面全体の背景を真っ白に固定
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
                    margin: const EdgeInsets.only(bottom: 16),
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
          color: vehicleBorderColor(vehicle), // ★ 舞＝赤、幸＝青
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(bgImage(vehicle)),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.7),
            BlendMode.srcATop,
          ),
        ),
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
  // ★ 乗換カード：黒枠＋白背景＋3行構成でスッキリ表示
  // ============================================================
  Widget _buildMultiLegCard(Map row, String vehicle, String routeType) {
    final parts = vehicle.split("→");
    final firstVehicle = parts[0];
    final secondVehicle = parts[1];

    final firstColor = vehicleBorderColor(firstVehicle);
    final secondColor = vehicleBorderColor(secondVehicle);

    // ●色タグ（車両名の右側）
    Widget colorDot(Color c) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2), // ★ 外枠は黒
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        color: Colors.white, // ★ カード背景も白で統一
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 前半便（1行）
          Row(
            children: [
              Text(
                "${formatTime(row['depart_time'])} → ${formatTime(row['first_arrive_time'])}　$firstVehicle",
                style: const TextStyle(
                  fontSize: 22, // ★ 直通カードと同じ
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              colorDot(firstColor), // ★ 車両名の右に色タグ
            ],
          ),

          const SizedBox(height: 6),

          // ② 乗換（駅名入り・太字なし・サイズ18）
          Row(
            children: [
              const Icon(Icons.arrow_downward, size: 20, color: Colors.black),
              const SizedBox(width: 4),
              const Text(
                "乗換（学園通り駅）",
                style: TextStyle(
                  fontSize: 18, // ★ 直通カードのラベルと同じ
                  // 太字なし
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ③ 後半便（1行）
          Row(
            children: [
              Text(
                "${formatTime(row['second_depart_time'])} → ${formatTime(row['arrive_time'])}　$secondVehicle",
                style: const TextStyle(
                  fontSize: 22, // ★ 直通カードと同じ
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              colorDot(secondColor), // ★ 車両名の右に色タグ
            ],
          ),
        ],
      ),
    );
  }
}
