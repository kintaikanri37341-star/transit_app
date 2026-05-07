import 'package:flutter/material.dart';
import 'dart:html' as html;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();

    // ★ 起動時の強制更新チェック（いったん無効化）
    /*
    html.window.navigator.serviceWorker?.getRegistrations().then((regs) {
      for (var reg in regs) {
        reg.update().then((_) {
          reg.onUpdateFound?.listen((event) {
            html.window.location.reload();
          });
        });
      }
    });
    */
  }

  void goHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: goHome,
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
