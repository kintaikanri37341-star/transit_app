import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'HomePage.dart';       // ← 追加
import 'search_page.dart';   // ← 経路検索画面

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

      // ★ ここが一番重要 ★
      home: const HomePage(),   // ← トップ画面を HomePage に変更

      routes: {
        "/search": (_) => const SearchPage(),  // ← 経路検索画面
      },
    );
  }
}
