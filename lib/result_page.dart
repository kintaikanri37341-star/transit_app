import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  Map<String, dynamic>? selectedRow; // ★ ① 選択中の便

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

  Color vehicleBorderColor(String vehicle) {
    if (vehicle.contains("舞")) return const Color(0xFFC62828);
    return const Color(0xFF1565C0);
  }

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

  // ★ お気に入り保存
  Future<void> saveFavorite(Map row) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("favorites") ?? [];
    list.add(jsonEncode(row));
    await prefs.setStringList("favorites", list);
  }

  // ★ ④ お気に入り追加ポップ
  void showAddedPopup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("お気に入り便に追加しました"),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ★ メニュー表示（①②③④すべて反映）
  void showTripMenu(Map row) {
    setState(() {
      selectedRow = row; // ① 選択した便だけ表示
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ② 背景暗転を消す
      barrierColor: Colors.transparent, // ② 暗くしない
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuItem(
                icon: Icons.alarm,
                text: "アラームを設定する", // ③ 文言変更
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 22),

              _menuItem(
                icon: Icons.route,
                text: "経路・時刻の詳細を見る",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailPage(row: row),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              _menuItem(
                icon: Icons.star,
                text: "お気に入り便に追加する",
                onTap: () async {
                  await saveFavorite(row);
                  Navigator.pop(context);
                  showAddedPopup(); // ④ ポップ表示
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // メニューを閉じたら一覧に戻す
      setState(() {
        selectedRow = null;
      });
    });
  }

  // ★ メニューアイテム（太字・22px・1行）
  Widget _menuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listToShow =
        selectedRow != null ? [selectedRow!] : results; // ★ ① 選択中は1件だけ表示

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.depart} → ${widget.arrive}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: listToShow.length,
              itemBuilder: (context, index) {
                final row = listToShow[index];
                final routeType = row['route_type'] as String;
                final vehicle = row['vehicle'] as String;

                final isDirectType =
                    routeType == "direct" || routeType == "direct_stopover";

                return GestureDetector(
                  onTap: () {
                    showTripMenu(row);
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

  // ★ 直通カード（元のまま）
  Widget _buildDirectCard(Map row, String vehicle, String routeType) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: vehicleBorderColor(vehicle),
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

  // ★ 乗換カード（元のまま）
  Widget _buildMultiLegCard(Map row, String vehicle, String routeType) {
    final parts = vehicle.split("→");
    final firstVehicle = parts[0];
    final secondVehicle = parts[1];

    final firstColor = vehicleBorderColor(firstVehicle);
    final secondColor = vehicleBorderColor(secondVehicle);

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
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "${formatTime(row['depart_time'])} → ${formatTime(row['first_arrive_time'])}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                firstVehicle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              colorDot(firstColor),
            ],
          ),

          const SizedBox(height: 6),

          const Row(
            children: [
              Icon(Icons.arrow_downward, size: 20, color: Colors.black),
              SizedBox(width: 4),
              Text(
                "乗換（学園通り駅）",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Text(
                "${formatTime(row['second_depart_time'])} → ${formatTime(row['arrive_time'])}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                secondVehicle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              colorDot(secondColor),
            ],
          ),
        ],
      ),
    );
  }
}
