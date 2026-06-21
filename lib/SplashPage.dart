import 'package:flutter/material.dart';
import 'dart:html' as html;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false; // ★ 多重遷移防止

  @override
  void initState() {
    super.initState();

    // ★ 起動時に強制更新チェック
    html.window.navigator.serviceWorker?.getRegistrations().then((regs) {
      for (var reg in regs) {
        reg.update().then((_) {
          reg.onUpdateFound?.listen((event) {
            html.window.location.reload();
          });
        });
      }
    });

    // ★ 3秒後に自動遷移
    Future.delayed(const Duration(seconds: 3), () {
      _goHome();
    });
  }

  void _goHome() {
    if (_navigated) return; // ★ すでに遷移済みなら何もしない
    _navigated = true;

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goHome, // ★ タップでも遷移
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash.png',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
