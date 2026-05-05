import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'result_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? depart;
  String? arrive;

  List<String> allStations = [];
  List<String> filteredStations = [];

  @override
  void initState() {
    super.initState();
    loadStations();
  }

  // 🔹 Supabase から駅一覧を取得
  Future<void> loadStations() async {
    final res = await Supabase.instance.client
        .from('trips_adjacent')
        .select('depart_station')
        .order('depart_station');

    final setStations = res
        .map((row) => row['depart_station'] as String)
        .toSet()
        .toList();

    setState(() {
      allStations = setStations;
      filteredStations = List.from(allStations);
    });
  }

  // 🔹 最近使った駅（出発 or 到着）を保存（最大5件）
  Future<void> saveRecentStation(String key, String station) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(key) ?? [];

    recent.remove(station);
    recent.insert(0, station);

    if (recent.length > 5) {
      recent = recent.sublist(0, 5);
    }

    await prefs.setStringList(key, recent);
  }

  // 🔹 最近使った駅を読み込む
  Future<List<String>> loadRecentStations(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  // 🔹 最近使った駅を削除
  Future<void> deleteRecentStation(String key, String station) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(key) ?? [];

    recent.remove(station);
    await prefs.setStringList(key, recent);
  }

  // 🔹 駅選択 BottomSheet
  void openStationSelector(bool isDepart) async {
    final key = isDepart ? 'recent_depart' : 'recent_arrive';
    List<String> recentStations = await loadRecentStations(key);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        String keyword = "";
        List<String> tempList = List.from(allStations);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔍 検索欄
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '駅名を検索',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) {
                      keyword = v;
                      tempList = allStations
                          .where((s) => s.contains(keyword))
                          .toList();
                      setModalState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // ⭐ 最近使った駅（削除ボタン付き）
                  if (recentStations.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '最近使った駅',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ...recentStations.map((station) => ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(station),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () async {
                              await deleteRecentStation(key, station);
                              recentStations =
                                  await loadRecentStations(key);
                              setModalState(() {});
                            },
                          ),
                          onTap: () async {
                            setState(() {
                              if (isDepart) {
                                depart = station;
                              } else {
                                arrive = station;
                              }
                            });

                            await saveRecentStation(key, station);
                            Navigator.pop(context);
                          },
                        )),

                    const Divider(),
                  ],

                  // 🔽 駅一覧
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: tempList.length,
                      itemBuilder: (_, i) {
                        final station = tempList[i];
                        return ListTile(
                          title: Text(station),
                          onTap: () async {
                            setState(() {
                              if (isDepart) {
                                depart = station;
                              } else {
                                arrive = station;
                              }
                            });

                            await saveRecentStation(key, station);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('経路検索')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 出発駅
            ElevatedButton(
              onPressed: () => openStationSelector(true),
              child: Text(depart ?? '出発駅を選択'),
            ),

            const SizedBox(height: 16),

            // 到着駅
            ElevatedButton(
              onPressed: () => openStationSelector(false),
              child: Text(arrive ?? '到着駅を選択'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: (depart != null && arrive != null)
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultPage(
                            depart: depart!,
                            arrive: arrive!,
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('検索する'),
            ),
          ],
        ),
      ),
    );
  }
}
