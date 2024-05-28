import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class Guest {
  final int id;
  final String name;
  final int? registrator;

  const Guest({required this.id, required this.name, required this.registrator});

  Widget draggableNameFeedback() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(name),
      ),
    );
  }
}

class Seatwish {
  final int uid;
  final List<String> seatWishes;
  final String note;

  const Seatwish({required this.uid, required this.seatWishes, required this.note});
}

class BallTable {
  final String id;
  final int seats;
  /// x and y between 0 and 1, scaled by multiplying with width and height
  Offset position;
  late Offset stablePosition;
  final bool rotated;

  BallTable({required this.id, required this.seats, required this.position, required this.rotated}) {
    stablePosition = position;
  }
}

class AppState extends ChangeNotifier {
  final Map<BallTable, List<Guest>> tableMap = {};
  List<Guest> guests = [];
  List<BallTable> tables = [];
  List<Seatwish> seatwishes = [];
  bool tablesMovable = false;

  Future<void> confirmTableMapUpdate() async {
    await File("table_map.json").writeAsString(jsonEncode(simplifyTableMap()));
    notifyListeners();
  }

  void updateGuestList(List<Guest> guestList) {
    guests = guestList;
    notifyListeners();
  }

  void updateTableList(List<BallTable> tableList) {
    tables = tableList;
    notifyListeners();
  }

  void updateSeatwishList(List<Seatwish> swList) {
    seatwishes = swList;
    notifyListeners();
  }

  void notifyDataChange() {
    notifyListeners();
  }

  void updateTablesMovable(bool val) {
    tablesMovable = val;
    notifyListeners();
  }

  BallTable? getTableForGuest(Guest guest) {
    return tableMap.entries.where((entry) => entry.value.contains(guest)).firstOrNull?.key;
  }

  Map<String, List<int>> simplifyTableMap() {
    return tableMap.map((entry, guests) => MapEntry(entry.id, guests.map((g) => g.id).toList()));
  }

  void loadTableMapFromSimpleForm(Map<String, List<int>> simpleMap) {
    simpleMap.forEach((tid, gids) => tableMap[tables.where((t) => t.id == tid).first] = gids.map((id) => guests.firstWhere((g) => g.id == id)).toList());
    notifyListeners();
  }

  Future<void> saveUpdatedTables() async {
    await File("updated-tables.csv").writeAsString(const ListToCsvConverter(delimitAllFields: true, eol: "\n").convert(
      [["tid", "seats", "posx", "posy", "rotated"]] + tables.map((tbl) => [tbl.id, tbl.seats.toString(), tbl.position.dx.toString(), tbl.position.dy.toString(), tbl.rotated ? "true" : ""]).toList(),
    ));
  }
}
