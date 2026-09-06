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

  Map<String, dynamic>? selectedRow;

  // カード位置取得用
  final Map<int, GlobalKey> cardKeys = {};
  double selectedTop = 0;

  // アニメーション制御
  bool showOverlay = false;
  bool fadeOutList = false;
  bool fadeInMenu = false;

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

  // 背景色（舞ちゃん＝ピンク、幸ちゃん＝青）
  Color vehicleBgColor(String vehicle) {
    if (vehicle.contains("舞")) return const Color(0xFFFFE4E1);
    return const Color(0xFFE0F0FF);
  }

  // 枠線色
  Color vehicleBorderColor(String vehicle) {
    if (vehicle.contains("舞")) return const Color(0xFFC62828);
    return const Color(0xFF1565C0);
  }

  // 背景画像
  String bgImage(String vehicle) {
    if (vehicle.contains("舞")) {
      return "assets/images/maichan.jpg";
    } else {
      return "assets/images/sachichan.jpg";
    }
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

  Future<void> saveFavorite(Map row) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("favorites") ?? [];

    final newRow = Map<String, dynamic>.from(row);
    newRow['depart'] = widget.depart;
    newRow['arrive'] = widget.arrive;

    list.add(jsonEncode(newRow));
    await prefs.setStringList("favorites", list);
  }

  void showAddedPopup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("お気に入り便に追加しました"),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // カードタップ時の処理
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

  @override
  Widget build(BuildContext context) {
    final listToShow = results;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.depart} → ${widget.arrive}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: fadeOutList ? 0 : 1,
            child: loading
                ? const Center(child: CircularProgressIndicator())
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
                          child: isDirectType
                              ? _buildDirectCard(row, vehicle, routeType)
                              : _buildMultiLegCard(row, vehicle, routeType),
                        ),
                      );
                    },
                  ),
          ),

          if (showOverlay)
            GestureDetector(
              onTap: closeOverlay,
              child: Container(
                color: Colors.white,
              ),
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
                            ? _buildDirectCard(row, vehicle, routeType)
                            : _buildMultiLegCard(row, vehicle, routeType);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: fadeInMenu ? 1 : 0,
                    child: Column(
                      children: [
                        _menuButton("経路・時刻の詳細を見る", Icons.route, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteDetailPage(row: selectedRow!),
                            ),
                          );
                        }),

                        const SizedBox(height: 22),

                        _menuButton("お気に入り便に追加する", Icons.star, () async {
                          await saveFavorite(selectedRow!);
                          showAddedPopup();
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

  // ★ 背景色を正しく反映する直通カード
  Widget _buildDirectCard(Map row, String vehicle, String routeType) {
    return Container(
      decoration: BoxDecoration(
        color: vehicleBgColor(vehicle), // ← 背景色を直接指定
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
            Colors.white.withOpacity(0.15), // ← 画像を薄くするだけ
            BlendMode.dstATop,              // ← 背景色を殺さないモード
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
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Text(
                routeLabel(routeType, vehicle),
                style: const TextStyle(
                  fontSize: 18,
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

  // ★ 背景色を正しく反映する乗換カード
  Widget _buildMultiLegCard(Map row, String vehicle, String routeType) {
    final parts = vehicle.split("→");
    final firstVehicle = parts[0];
    final secondVehicle = parts[1];

    final firstColor = vehicleBorderColor(firstVehicle);
    final secondColor = vehicleBorderColor(secondVehicle);

    Widget dot(Color c) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
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
                ),
              ),

              const SizedBox(width: 6),

              dot(firstColor),
            ],
          ),

          const SizedBox(height: 6),

          const Row(
            children: [
              Icon(Icons.arrow_downward, size: 20),
              SizedBox(width: 4),
              Text(
                "乗換（学園通り駅）",
                style: TextStyle(
                  fontSize: 18,
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
                ),
              ),

              const SizedBox(width: 6),

              dot(secondColor),
            ],
          ),
        ],
      ),
    );
  }
}
