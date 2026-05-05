import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ★ pubspec.yaml の name: transit_app を使う（小文字）
import 'package:transit_app/SplashPage.dart';
import 'package:transit_app/HomePage.dart';
import 'package:transit_app/search_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== Flutter 起動チェック: OK ===');

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

      home: const SplashPage(),

      routes: {
        "/home": (_) => const HomePage(),
        "/search": (_) => const SearchPage(),
      },
    );
  }
}
