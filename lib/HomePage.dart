import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/header_logo.jpg",
              height: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              "三木町コミュニティバス",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          const SizedBox(height: 40),

          Expanded(
            flex: 15,
            child: Center(
              child: Image.asset(
                "assets/images/main_logo_new.png",
                fit: BoxFit.contain,
              ),
            ),
          ),

          Expanded(
            flex: 27,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _menuButton(
                            color: const Color(0xFFB3E5FC),
                            icon: Icons.map,
                            text: "バス停を\n探す",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ImagePage(
                                    title: "バス停を探す",
                                    imagePath: "assets/images/heiyabu_rosen_V2.jpg",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _menuButton(
                            color: const Color(0xFFC8E6C9),
                            icon: Icons.search,
                            text: "経路・時刻表\n検索",
                            onTap: () {
                              Navigator.pushNamed(context, "/search");
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _menuButton(
                            color: const Color(0xFFF8BBD0),
                            icon: Icons.location_on,
                            text: "バスの\n現在地",
                            onTap: () {
                              _openUrl("http://mikishishi.bus-go.com/info/index.php");
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _menuButton(
                            color: const Color(0xFFFFF9C4),
                            icon: Icons.help_outline,
                            text: "利用方法等",
                            onTap: () {
                              _openUrl("https://www.town.miki.lg.jp/life/dtl.php?hdnKey=1006");
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _menuButton(
                            color: const Color(0xFFE1BEE7),
                            icon: Icons.directions_bus_filled,
                            text: "山南地区\nデマンドバス",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ImagePage(
                                    title: "山南地区デマンドバス",
                                    imagePath: "assets/images/demand-bus.jpg",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ★★★ ここだけ変更（名前＋色＋内部余白）★★★
                        Expanded(
                          child: _menuButton(
                            color: const Color(0xFFFFCC80), // オレンジ
                            icon: Icons.stars,
                            text: "お気に入り便", // ← 改行なし
                            padding: const EdgeInsets.symmetric(vertical: 6), // ← 内部余白を小さく
                            onTap: () {},
                          ),
                        ),
                        // ★★★ ここだけ変更 ★★★
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SizedBox(
            height: 70,
            width: double.infinity,
            child: Image.asset(
              "assets/images/footer_logo.png",
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton({
    required Color color,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 12), // ★ デフォルト余白
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: padding, // ★ ここに適用
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: Colors.black87),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImagePage extends StatelessWidget {
  final String title;
  final String imagePath;

  const ImagePage({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 10.0,
          child: Image.asset(imagePath),
        ),
      ),
    );
  }
}
