import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ここを相対パス → package パスに変更
import 'package:transit_app/SplashPage.dart';   // スプラッシュ画面
import 'package:transit_app/HomePage.dart';     // ホーム画面
import 'package:transit_app/search_page.dart';  // 経路検索画面

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== Flutter 起動チェック: OK ===');

  // Supabase 初期化テスト
  try {
    await Supabase.initialize(
      url: 'https://ntctviniqtywczrdeubc.supabase.co',
      anonKey: 'sb_publishable_m1cEMoxflhuJrbpl6UfMtw_-xeGFlS5',
    );
    print('=== Supabase.initialize 成功 ===');
  } catch (e) {
    print('=== Supabase.initialize 失敗 ===');
    print(e);
  }

  // Supabase クエリテスト
  try {
    final response = await Supabase.instance.client
        .from('trips_final')
        .select()
        .limit(1);

    print('=== Supabase クエリ成功 ===');
    print(response);
  } catch (e) {
    print('=== Supabase クエリ失敗 ===');
    print(e);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transit App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ★ 起動時は SplashPage を表示する
      home: const SplashPage(),

      routes: {
        "/home": (_) => const HomePage(),     // ホーム画面
        "/search": (_) => const SearchPage(), // 経路検索画面
      },
    );
  }
}
