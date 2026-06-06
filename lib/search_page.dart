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
  List<String> tempList = []; // ← 検索結果が消えないように外へ移動

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
      tempList = List.from(allStations);
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

    TextEditingController controller = TextEditingController();
    String keyword = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔍 検索欄
                  TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      labelText: '駅名を検索',
                      labelStyle: const TextStyle(fontSize: 20),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: keyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                controller.clear();
                                setModalState(() {
                                  keyword = "";
                                  tempList = allStations;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      keyword = v;
                      setModalState(() {
                        tempList = allStations
                            .where((s) => s.contains(keyword))
                            .toList();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // ⭐ 最近使った駅
                  if (recentStations.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '最近使った駅',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ...recentStations.map((station) => ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(
                            station,
                            style: const TextStyle(fontSize: 20),
                          ),
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: tempList.length,
                      itemBuilder: (_, i) {
                        final station = tempList[i];
                        return ListTile(
                          title: Text(
                            station,
                            style: const TextStyle(fontSize: 20),
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
      appBar: AppBar(title: const Text('経路検索', style: TextStyle(fontSize: 22))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 出発駅
            ElevatedButton(
              onPressed: () => openStationSelector(true),
              child: Text(
                depart ?? '出発駅を選択',
                style: const TextStyle(fontSize: 20),
              ),
            ),

            const SizedBox(height: 16),

            // 到着駅
            ElevatedButton(
              onPressed: () => openStationSelector(false),
              child: Text(
                arrive ?? '到着駅を選択',
                style: const TextStyle(fontSize: 20),
              ),
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
              child: const Text('検索する', style: TextStyle(fontSize: 20)),
            ),

            // 🔻 注意書き（上下中央配置）
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '日曜日・祝日・年末年始は運休です。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '交通状況により、到着時間が遅れることがあります。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'あらかじめご承知おきください。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
