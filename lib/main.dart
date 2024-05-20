import 'package:flutter/material.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
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

class GuestData {
  final int id;
  final String name;
  final int? registrator;

  const GuestData({required this.id, required this.name, required this.registrator});
}

class _MyHomePageState extends State<MyHomePage> {
  late SplitViewController _splitController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        title: Text(widget.title),
      ),
      body: SplitView(
        controller: _splitController,
        gripSize: 5,
        viewMode: SplitViewMode.Horizontal,
        children: [
          Zoomable(
            clipBehavior: Clip.none,
            constrained: false,
            child: SizedBox(
              width: 2500,
              height: 2500,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 100,
                    top: 50,
                    child: Container(
                      color: Colors.amber,
                      width: 1222,
                      height: 800,
                    ),
                  ),
                  DragTarget(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey,
                        child: Text(candidateData.join(", ")),
                      );
                    },
                    onWillAcceptWithDetails: (details) {
                      // TODO: check if guest can sit at this table
                      return true;
                    },
                    onAcceptWithDetails: (details) {
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              children: const [
                ListTile(
                  title: Text("guest 1"),
                  subtitle: Draggable(
                    feedback: Card.outlined(
                      child: Text("dragging"),
                    ),
                    data: GuestData(id: 1, name: "guest 1", registrator: null),
                    child: Card.outlined(
                      child: Text("guest 1"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    _splitController = SplitViewController(weights: [.75, .25]);
    super.initState();
  }

  @override
  void dispose() {
    _splitController.dispose();
    super.dispose();
  }
}
