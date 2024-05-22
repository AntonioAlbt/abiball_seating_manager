import 'dart:convert';
import 'dart:io';

import 'package:abiball_seating_manager/data.dart';
import 'package:abiball_seating_manager/table_display.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:split_view/split_view.dart';
import 'package:zoomable_widget/zoomable_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abiball-Sitzplan-Verwalter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Abiball-Sitzplan-Verwalter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SplitViewController _splitController;
  bool _loading = false;
  late AppState _state;
  bool _onlyGroupsWithUnplaced = false;
  bool _sortBySize = false;
  String _search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        title: Text(widget.title),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ChangeNotifierProvider<AppState>(
        create: (_) => _state,
        child: SplitView(
          controller: _splitController,
          gripSize: 5,
          viewMode: SplitViewMode.Horizontal,
          children: [
            Zoomable(
              clipBehavior: Clip.none,
              constrained: false,
              minScale: .1,
              maxScale: 3,
              child: const TableDisplay(),
            ),
            Consumer<AppState>(
              builder: (context, state, _) {
                return Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: ListView(
                    children: [
                      const ListTile(
                        title: Text("Verwendungsinfo"),
                        subtitle: Text("Aktionen:\n- Zoomen: Linksklick + Scrollen\n- Hinzufügen/Verschieben: Person auf Tisch verschieben\n- Zum Entfernen, Person auf aktuellen Tisch verschieben.\n- Gruppeneintrag anfassen, um Personengruppe zu verwenden."),
                      ),
                      CheckboxListTile(
                        title: const Text("Nach Gruppengröße sortieren"),
                        value: _sortBySize,
                        onChanged: (newVal) => setState(() => _sortBySize = newVal!),
                      ),
                      CheckboxListTile(
                        title: const Text("Nur Gruppen mit Personen ohne Tisch anzeigen"),
                        value: _onlyGroupsWithUnplaced,
                        onChanged: (newVal) => setState(() => _onlyGroupsWithUnplaced = newVal!),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          onChanged: (newVal) => setState(() => _search = newVal),
                          decoration: const InputDecoration(hintText: "Suche nach Namen"),
                        ),
                      ),
                    ] + (groupGuests(state.guests)..sort((a, b) => _sortBySize ? b.length.compareTo(a.length) : a.first.name.compareTo(b.first.name)))
                    .where((gr) => _onlyGroupsWithUnplaced ? gr.any((g) => state.getTableForGuest(g) == null) : true)
                    .where((gr) => _search != "" ? gr.map((g) => g.name).join(", ").toLowerCase().contains(_search.toLowerCase()) : true)
                    .map((group) {
                      final swish = state.seatwishes.where((w) => w.uid == group.first.id).toList().firstOrNull;
                      return ListTile(
                        title: Text("Gruppe von ${group.first.name}"),
                        subtitle: Draggable(
                          feedback: Column(
                            children: group.map((g) => g.draggableNameFeedback()).toList(),
                          ),
                          data: group,
                          child: Card(
                            child: Column(
                              children: [
                                if (swish != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    child: Text(
                                      "Sitzwunsch: mit ${swish.seatWishes.join(", ").replaceAll(group.length > 1 ? group.skip(1).map((g) => g.name).join(", ") : "dhwuduh3w8", "Gästen")}",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                if ((swish?.note ?? "").trim() != "") Padding(
                                  padding: const EdgeInsets.only(left: 2, right: 2, bottom: 4),
                                  child: Text("Notiz: ${swish?.note}", textAlign: TextAlign.center),
                                ),
                                ...group.map(
                                  (guest) => (){
                                    final current = state.getTableForGuest(guest);
                                    final widget = Card.outlined(
                                      color: current != null ? Colors.blueGrey.shade200 : Colors.redAccent.shade100.withOpacity(.2),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                        child: Text("${guest.name}${current != null ? " - Tisch ${current.id}" : ""}"),
                                      ),
                                    );
                                    return Draggable(feedback: guest.draggableNameFeedback(), data: guest, child: widget);
                                  }(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    _splitController = SplitViewController(weights: [.75, .25]);
    super.initState();

    _state = AppState();
    _loadData();
  }

  @override
  void dispose() {
    _splitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    // await Future.delayed(const Duration(seconds: 2));

    final regsData = const CsvToListConverter().convert(await File("registrations.csv").readAsString(), eol: "\n");
    final guests = <Guest>[];
    for (final reg in regsData) {
      if (int.tryParse(reg[0]) == null) continue;
      guests.add(Guest(id: int.parse(reg[0]), name: reg[1], registrator: int.tryParse(reg[5])));
    }
    _state.guests = guests;

    final seatwishData = const CsvToListConverter().convert(await File("seatwishes.csv").readAsString(), eol: "\n");
    final seatwishes = <Seatwish>[];
    for (final sw in seatwishData) {
      if (int.tryParse(sw[0]) == null) continue;
      seatwishes.add(Seatwish(uid: int.parse(sw[0]), seatWishes: sw[1].split("|"), note: sw[2] ?? ""));
    }
    _state.seatwishes = seatwishes;

    final tableData = const CsvToListConverter().convert(await File("tables.csv").readAsString(), eol: "\n");
    final tables = <BallTable>[];
    for (final tbl in tableData) {
      if (int.tryParse(tbl[1]) == null) continue;
      tables.add(
        BallTable(
          id: tbl[0],
          seats: int.parse(tbl[1]),
          position: Offset(double.parse(tbl[2]), double.parse(tbl[3])),
          rotated: tbl[4].trim() != "" && tbl[4].trim().toLowerCase() != "false"
        ),
      );
    }
    _state.tables = tables;

    final tblMapFile = File("table_map.json");
    if (await tblMapFile.exists()) {
      _state.loadTableMapFromSimpleForm((jsonDecode(await tblMapFile.readAsString()) as Map<dynamic, dynamic>).cast<String, List<dynamic>>().map((e1, e2) => MapEntry(e1, e2.cast<int>())));
    }

    setState(() {
      _loading = false;
    });
  }
}

List<List<Guest>> groupGuests(List<Guest> guests) {
  final output = <List<Guest>>[];
  for (final guest in guests) {
    if (guest.registrator != null) continue;
    output.add([guest, ...guests.where((g) => g.registrator == guest.id)]);
  }
  return output;
}
