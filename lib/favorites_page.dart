import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'route_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favorites = [];
  Map<String, dynamic>? selectedRow;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("favorites") ?? [];

    setState(() {
      favorites = list.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> removeFavorite(Map row) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("favorites") ?? [];

    list.remove(jsonEncode(row));
    await prefs.setStringList("favorites", list);

    await loadFavorites();
  }

  void showTripMenu(Map row) {
    setState(() {
      selectedRow = Map<String, dynamic>.from(row);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
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
                text: "アラームを設定する",
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
                icon: Icons.delete,
                text: "お気に入り便から削除する",
                onTap: () async {
                  await removeFavorite(row);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        selectedRow = null;
      });
    });
  }

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

  Color vehicleBorderColor(String vehicle) {
    if (vehicle.contains("舞")) return const Color(0xFFC62828);
    return const Color(0xFF1565C0);
  }

  String bgImage(String vehicle) {
    if (vehicle.contains("舞")) return "assets/images/maichan.jpg";
    return "assets/images/sachichan.jpg";
  }

  String formatTime(String? t) {
    if (t == null) return "";
    return t.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final listToShow =
        selectedRow != null ? [selectedRow!] : favorites;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("お気に入り便"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: listToShow.isEmpty
          ? const Center(
              child: Text(
                "お気に入り便はありません",
                style: TextStyle(fontSize: 20),
              ),
            )
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
                        ? _buildDirectCard(row, vehicle)
                        : _buildMultiLegCard(row, vehicle),
                  ),
                );
              },
            ),
    );
  }

  // ★ 直通カード（駅名表示あり）
  Widget _buildDirectCard(Map row, String vehicle) {
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
            Colors.white.withOpacity(0.18),
            BlendMode.srcATop,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ★ 駅名（ResultPage で保存したもの）
          Text(
            "${row['depart']} → ${row['arrive']}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "${formatTime(row['depart_time'])} → ${formatTime(row['arrive_time'])}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "直通（${row['vehicle']}）",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ★ 乗換カード（駅名表示あり）
  Widget _buildMultiLegCard(Map row, String vehicle) {
    final parts = vehicle.split("→");
    final firstVehicle = parts[0];
    final secondVehicle = parts[1];

    final firstColor = vehicleBorderColor(firstVehicle);
    final secondColor = vehicleBorderColor(secondVehicle);

    Widget dot(Color c) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
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
          // ★ 駅名
          Text(
            "${row['depart']} → ${row['arrive']}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Text(
                "${formatTime(row['depart_time'])} → ${formatTime(row['first_arrive_time'])}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(firstVehicle, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              dot(firstColor),
            ],
          ),

          const SizedBox(height: 6),

          const Row(
            children: [
              Icon(Icons.arrow_downward, size: 20),
              SizedBox(width: 4),
              Text("乗換（学園通り駅）", style: TextStyle(fontSize: 18)),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Text(
                "${formatTime(row['second_depart_time'])} → ${formatTime(row['arrive_time'])}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(secondVehicle, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              dot(secondColor),
            ],
          ),
        ],
      ),
    );
  }
}
