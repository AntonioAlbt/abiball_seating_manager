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
              // child: SizedBox(
              //   width: 2500,
              //   height: 2500,
              //   child: Stack(
              //     children: <Widget>[
              //       Positioned(
              //         left: 100,
              //         top: 50,
              //         child: Container(
              //           color: Colors.amber,
              //           width: 1222,
              //           height: 800,
              //         ),
              //       ),
              //       DragTarget(
              //         builder: (context, candidateData, rejectedData) {
              //           return Container(
              //             width: 100,
              //             height: 100,
              //             color: Colors.grey,
              //             child: Text(candidateData.join(", ")),
              //           );
              //         },
              //         onWillAcceptWithDetails: (details) {
              //           // TODO: check if guest can sit at this table
              //           return true;
              //         },
              //         onAcceptWithDetails: (details) {
              //         },
              //       ),
              //     ],
              //   ),
              // ),
            ),
            Container(
              height: double.infinity,
              width: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView(
                children: groupGuests(_state.guests).map((group) {
                  final swish = _state.seatwishes.where((w) => w.uid == group.first.id).toList().firstOrNull;
                  return ListTile(
                    title: Text("Gruppe von ${group.first.name}"),
                    subtitle: Card(
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
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Text("Notiz: ${swish?.note}", textAlign: TextAlign.center),
                          ),
                          ...group.map(
                            (guest) => (){
                              final widget = Card.outlined(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                  child: Text(guest.name),
                                ),
                              );
                              return Draggable(feedback: widget, data: guest, child: widget);
                            }(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
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
