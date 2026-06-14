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
  List<String> tempList = [];

  @override
  void initState() {
    super.initState();
    loadStations();
  }

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

  Future<List<String>> loadRecentStations(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  Future<void> deleteRecentStation(String key, String station) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(key) ?? [];

    recent.remove(station);
    await prefs.setStringList(key, recent);
  }

  void openStationSelector(bool isDepart) async {
    final key = isDepart ? 'recent_depart' : 'recent_arrive';
    List<String> recentStations = await loadRecentStations(key);

    TextEditingController controller = TextEditingController();
    String keyword = "";

    tempList = List.from(allStations);

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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const SizedBox.shrink(),
                    ),
                  ),

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
                        tempList = v.isEmpty
                            ? allStations
                            : allStations.where((s) => s.contains(v)).toList();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

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

  void _swapStations() {
    setState(() {
      final tmp = depart;
      depart = arrive;
      arrive = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseButton = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 2),
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );

    final searchButtonStyle = (depart != null && arrive != null)
        ? ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF8BBD0),
            foregroundColor: Colors.black,
            side: const BorderSide(color: Color(0xFFC62828), width: 3),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC8E6C9),
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 2),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          );

    // ★ 小型入替ボタンの共通スタイル
    final swapMiniButton = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFF59D),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      minimumSize: const Size(60, 40),
      side: const BorderSide(color: Colors.black, width: 2),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('経路・時刻表検索', style: TextStyle(fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '出発駅',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // ★ 出発駅ボタン + 右端ミニ入替
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: baseButton.copyWith(
                      backgroundColor:
                          const MaterialStatePropertyAll(Color(0xFFC8E6C9)),
                    ),
                    onPressed: () => openStationSelector(true),
                    child: Text(depart ?? '出発駅を選択'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: swapMiniButton,
                  onPressed: _swapStations,
                  child: Row(
                    children: const [
                      Icon(Icons.swap_vert, size: 20, color: Colors.black),
                      SizedBox(width: 4),
                      Text("入替"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              '到着駅',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // ★ 到着駅ボタン + 右端ミニ入替
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: baseButton.copyWith(
                      backgroundColor:
                          const MaterialStatePropertyAll(Color(0xFFC8E6C9)),
                    ),
                    onPressed: () => openStationSelector(false),
                    child: Text(arrive ?? '到着駅を選択'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: swapMiniButton,
                  onPressed: _swapStations,
                  child: Row(
                    children: const [
                      Icon(Icons.swap_vert, size: 20, color: Colors.black),
                      SizedBox(width: 4),
                      Text("入替"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: searchButtonStyle,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search, size: 26, color: Colors.black),
                  SizedBox(width: 8),
                  Text('検索する'),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '日曜日・祝日・年末年始は運休です。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '交通状況により、到着時間が遅れることがあります。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'あらかじめご承知おきください。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
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
