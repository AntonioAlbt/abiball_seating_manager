import 'package:abiball_seating_manager/data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const kScale = 1.0;

const kWidth = 1536 * kScale;
const kHeight = 2048 * kScale;
const kTextBoxSize = 50 * kScale;
const kTableSize = 35 * kScale;
const kTextPadding = 4 * kScale;
const kFontSize = 14 * kScale;

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
        final seaters = state.tableMap[widget.table] ?? [];
        Widget toSeatWidget(int index) {
          final widget = SizedBox.square(
            dimension: kTextBoxSize,
            child: Padding(
              padding: const EdgeInsets.all(kTextPadding),
              child: Container(
                decoration: (seaters.length <= index) ? BoxDecoration(border: Border.all()) : null,
                child: (seaters.length <= index)
                    ? null
                    : Text(
                        seaters[index].name.replaceAll(" ", "\u00a0"), // 00a0 -> unbreakable space
                        style: const TextStyle(fontSize: kFontSize, height: 0),
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          );
          if (seaters.length <= index) return widget;
          return Draggable(
            feedback: seaters[index].draggableNameFeedback(),
            data: seaters[index],
            child: widget,
          );
        }
        return DragTarget(
          onWillAcceptWithDetails: (details) {
            if (details.data is Guest || details.data is List<Guest>) {
              // if ((state.tableMap[widget.table]?.length ?? 0) + 1 > widget.table.seats) return false;
              return true;
            }
            return false;
          },
          onAcceptWithDetails: (details) {
            for (final data in (details.data is Guest ? [details.data] : details.data is List<Guest> ? (details.data as List<Guest>) : [])) {
              if (data is Guest) {
                final current = state.getTableForGuest(data);
                if (current?.id == widget.table.id) {
                  state.tableMap[widget.table]!.remove(data);
                  continue;
                }

                if ((state.tableMap[widget.table]?.length ?? 0) + 1 > widget.table.seats) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dieser Tisch ist voll."), duration: Duration(milliseconds: 500)));
                  break;
                }

                if (current == null) {
                  state.tableMap[widget.table] = (state.tableMap[widget.table] ?? [])..add(data);
                } else {
                  state.tableMap[current]!.remove(data);
                  state.tableMap[widget.table] = (state.tableMap[widget.table] ?? [])..add(data);
                }
              }
            }
            state.confirmTableMapUpdate();
            return;
          },
          builder: (context, candidates, rejected) {
            if (widget.table.seats == 8) {
              return Column(
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
                      toSeatWidget(7),
                      ActualTableBlock(
                        widget.table,
                        longBoiii: false,
                        highlight: candidates.isNotEmpty,
                        smallText: true,
                        badHighlight: (state.tableMap[widget.table]?.length ?? 0) + candidates.length > widget.table.seats,
                        full: (state.tableMap[widget.table]?.length ?? 0) >= widget.table.seats,
                      ),
                      toSeatWidget(3),
                    ],
                  ),
                  Row(
                    children: [
                      toSeatWidget(6),
                      toSeatWidget(5),
                      toSeatWidget(4),
                    ],
                  ),
                ],
              );
            } else if (widget.table.seats <= 12 && !widget.table.rotated) {
              return Column(
                children: [
                  Row(
                    children: List.generate(6, (i) => toSeatWidget(i)),
                  ),
                  ActualTableBlock(
                    widget.table,
                    longBoiii: true,
                    highlight: candidates.isNotEmpty,
                    smallText: false,
                    badHighlight: (state.tableMap[widget.table]?.length ?? 0) + candidates.length > widget.table.seats,
                    full: (state.tableMap[widget.table]?.length ?? 0) >= widget.table.seats,
                  ),
                  Row(
                    children: List.generate(widget.table.seats - 6, (i) => toSeatWidget(i + 6)),
                  ),
                ],
              );
            } else if (widget.table.seats <= 12 && widget.table.rotated) {
              return Row(
                children: [
                  Column(
                    children: List.generate(6, (i) => toSeatWidget(i)),
                  ),
                  ActualTableBlock(
                    widget.table,
                    longBoiii: true,
                    highlight: candidates.isNotEmpty,
                    smallText: false,
                    badHighlight: (state.tableMap[widget.table]?.length ?? 0) + candidates.length > widget.table.seats,
                    full: (state.tableMap[widget.table]?.length ?? 0) >= widget.table.seats,
                  ),
                  Column(
                    children: List.generate(widget.table.seats - 6, (i) => toSeatWidget(i + 6)),
                  ),
                ],
              );
            } else {
              return Container(
                decoration: BoxDecoration(border: Border.all()),
                child: Text("${widget.table.id} -> unknown size: ${widget.table.seats}"),
              );
            }
          },
        );
      },
    );
  }
}

class ActualTableBlock extends StatelessWidget {
  const ActualTableBlock(
    this.table,
    {
      super.key,
      required this.longBoiii,
      required this.highlight,
      required this.smallText,
      required this.badHighlight,
      required this.full,
    }
  );

  final BallTable table;
  final bool longBoiii;
  final bool highlight;
  final bool smallText;
  final bool badHighlight;
  final bool full;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kTextBoxSize * (longBoiii && !table.rotated ? 6 : 1),
      height: kTextBoxSize * (longBoiii && table.rotated ? 6 : 1),
      child: Center(
        child: SizedBox(
          width: (longBoiii && !table.rotated ? (kTextBoxSize * 6) : kTableSize),
          height: (longBoiii && table.rotated ? (kTextBoxSize * 6) : kTableSize),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: badHighlight ? Colors.red : highlight ? Colors.green : full ? Colors.blueGrey.shade800 : Colors.blue.shade800,
                width: 3,
              ),
              color: badHighlight
                  ? Colors.red.withOpacity(.5)
                  : highlight
                  ? Colors.green.withOpacity(.5)
                  : full
                  ? Colors.blueGrey.shade800.withOpacity(.4)
                  : Colors.blue.shade800.withOpacity(.25),
            ),
            child: Center(
              child: Text(
                "${table.id}${(table.rotated ? "\n" : " ")}(${table.seats})",
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: smallText ? const TextStyle(fontSize: 12, height: 0) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
