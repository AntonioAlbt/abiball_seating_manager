import 'package:flutter/material.dart';

class Guest {
  final int id;
  final String name;
  final int? registrator;

  const Guest({required this.id, required this.name, required this.registrator});
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
  final Offset position;
  final bool rotated;

  const BallTable({required this.id, required this.seats, required this.position, required this.rotated});
}

class AppState extends ChangeNotifier {
  final Map<BallTable, List<Guest>> tableMap = {};
  List<Guest> guests = [];
  List<BallTable> tables = [
    const BallTable(id: "2.1", seats: 8, position: Offset(.1, .1), rotated: false),
    const BallTable(id: "2.2", seats: 8, position: Offset(.1, .01), rotated: false),
  ];
  List<Seatwish> seatwishes = [];

  void notifyTableMapUpdate() {
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
}
