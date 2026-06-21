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

  final Map<int, GlobalKey> cardKeys = {};
  double selectedTop = 0;

  bool showOverlay = false;
  bool fadeOutList = false;
  bool fadeInMenu = false;

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

    // ★ ② 削除ポップアップ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("お気に入り便から削除しました"),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void onSelectRow(Map row, int index) {
    final key = cardKeys[index];
    if (key == null) return;

    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final pos = box.localToGlobal(Offset.zero);

    setState(() {
      selectedRow = Map<String, dynamic>.from(row);
      selectedTop = pos.dy;
      showOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 10), () {
      setState(() => fadeOutList = true);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => fadeInMenu = true);
    });
  }

  void closeOverlay() {
    setState(() {
      fadeInMenu = false;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        fadeOutList = false;
      });
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        showOverlay = false;
        selectedRow = null;
      });
    });
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
    final listToShow = favorites;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("お気に入り便"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: fadeOutList ? 0 : 1,
            child: listToShow.isEmpty
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
                      cardKeys[index] = GlobalKey();

                      final row = listToShow[index];
                      final routeType = row['route_type'] as String;
                      final vehicle = row['vehicle'] as String;

                      final isDirectType =
                          routeType == "direct" || routeType == "direct_stopover";

                      return GestureDetector(
                        onTap: () => onSelectRow(row, index),
                        child: Container(
                          key: cardKeys[index],
                          margin: const EdgeInsets.only(bottom: 16),
                          width: double.infinity, // ★ ① 横幅を画面いっぱいに固定
                          child: isDirectType
                              ? _buildDirectCard(row, vehicle)
                              : _buildMultiLegCard(row, vehicle),
                        ),
                      );
                    },
                  ),
          ),

          if (showOverlay)
            GestureDetector(
              onTap: closeOverlay,
              child: Container(color: Colors.white),
            ),

          if (showOverlay && selectedRow != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: fadeOutList
                  ? MediaQuery.of(context).size.height * 0.22
                  : selectedTop,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: fadeInMenu ? 1 : 0,
                    child: GestureDetector(
                      onTap: closeOverlay,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 4, bottom: 8),
                        child: Text(
                          "×",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: closeOverlay,
                    child: Builder(
                      builder: (_) {
                        final row = selectedRow!;
                        final routeType = row['route_type'] as String;
                        final vehicle = row['vehicle'] as String;

                        final isDirectType =
                            routeType == "direct" || routeType == "direct_stopover";

                        return isDirectType
                            ? _buildDirectCard(row, vehicle)
                            : _buildMultiLegCard(row, vehicle);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: fadeInMenu ? 1 : 0,
                    child: Column(
                      children: [
                        _menuButton("アラームを設定する", Icons.alarm, () {}),
                        const SizedBox(height: 22),
                        _menuButton("経路・時刻の詳細を見る", Icons.route, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteDetailPage(row: selectedRow!),
                            ),
                          );
                        }),
                        const SizedBox(height: 22),
                        _menuButton("お気に入り便から削除する", Icons.delete, () async {
                          await removeFavorite(selectedRow!);
                          closeOverlay();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuButton(String text, IconData icon, VoidCallback onTap) {
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectCard(Map row, String vehicle) {
    return Container(
      width: double.infinity, // ★ ① 横幅を固定
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
      width: double.infinity, // ★ ① 横幅を固定
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
