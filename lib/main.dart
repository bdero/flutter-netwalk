import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'netwalk_controller.dart';

void main() {
  runApp(Root());
}

class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netwalk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameView(title: 'Small'),
    );
  }
}

class GameView extends StatefulWidget {
  final String title;

  GameView({Key? key, required this.title}) : super(key: key);

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final controller = NetwalkController(10, 10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            return Stack(
              children: [
                Container(
                  color: Colors.lightBlueAccent,
                ),
                controller.buildWidget(),
              ],
            );
          },
        ),
      ),
    );
  }
}
