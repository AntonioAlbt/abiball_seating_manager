import 'package:abiball_seating_manager/data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const kScale = 1.0;

const kWidth = 1536 * kScale;
const kHeight = 2048 * kScale;
const kTextBoxSize = 40 * kScale;
const kTableSize = 30 * kScale;
const kTextPadding = 8 * kScale;

class TableDisplay extends StatefulWidget {
  const TableDisplay({super.key});

  @override
  State<TableDisplay> createState() => _TableDisplayState();
}

class _TableDisplayState extends State<TableDisplay> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SizedBox(
          width: kWidth,
          height: kHeight,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 3)
            ),
            child: Stack(
              children: [
                ...state.tables.map((table) => Positioned(
                  left: table.position.dx * kWidth,
                  top: table.position.dy * kHeight,
                  child: TableWidget(table),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TableWidget extends StatefulWidget {
  final BallTable table;

  const TableWidget(this.table, {super.key});

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (widget.table.seats == 8) {
          final seaters = state.tableMap[widget.table] ?? [];
          Widget toSeatWidget(int index) {
            final widget = SizedBox.square(
              dimension: kTextBoxSize,
              child: Padding(
                padding: const EdgeInsets.all(kTextPadding),
                child: Container(
                  decoration: BoxDecoration(border: Border.all()),
                  child: (seaters.length <= index) ? null : Text(seaters[index].name),
                ),
              ),
            );
            if (seaters.length <= index) return widget;
            return Draggable(
              feedback: widget,
              data: seaters[index],
              child: widget,
            );
          }
          return DragTarget(
            onWillAcceptWithDetails: (details) {
              if (details.data is Guest) {
                // TODO: check if table has free spots
                return true;
              }
              return false;
            },
            onAcceptWithDetails: (details) {
              if (details.data is Guest) {
                // TODO: put/move guest to table
                return;
              }
              return;
            },
            builder: (context, candidates, rejected) => Column(
              children: [
                Row(
                  children: [
                    toSeatWidget(0),
                    toSeatWidget(1),
                    toSeatWidget(2),
                  ],
                ),
                Row(
                  children: [
                    toSeatWidget(8),
                    SizedBox.square(
                      dimension: kTextBoxSize,
                      child: Center(
                        child: SizedBox.square(
                          dimension: kTableSize,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: candidates.isEmpty ? Colors.blue.shade800 : Colors.green,
                                width: 3,
                              ),
                              color: candidates.isEmpty ? Colors.blue.shade800.withOpacity(.25) : Colors.green.withOpacity(.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    toSeatWidget(3),
                  ],
                ),
                Row(
                  children: [
                    toSeatWidget(4),
                    toSeatWidget(5),
                    toSeatWidget(6),
                  ],
                ),
              ],
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(border: Border.all()),
            child: Text("${widget.table.id} -> unknown size: ${widget.table.seats}"),
          );
        }
      },
    );
  }
}
