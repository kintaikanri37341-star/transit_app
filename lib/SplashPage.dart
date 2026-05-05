import 'package:flutter/material.dart';
import 'dart:html' as html;

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  void checkForUpdate() {
    html.window.navigator.serviceWorker?.getRegistrations().then((regs) {
      for (var reg in regs) {
        reg.update().then((_) {
          // 新しい SW が見つかったら即リロード
          reg.onUpdateFound?.listen((event) {
            html.window.location.reload();
          });
        });
      }
    });
  }

  void goHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    // 画面描画後に強制更新チェックを実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate();
    });

    return GestureDetector(
      onTap: () => goHome(context),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'タップしてスタート',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
