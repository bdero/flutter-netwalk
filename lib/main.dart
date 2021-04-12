import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'netwalk_input.dart';
import 'netwalk_renderbox.dart';

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
  final String? title;

  GameView({Key? key, this.title}) : super(key: key);

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final inputState = NetwalkInput(10, 10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Container(
        child: LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            return Stack(
              children: [
                Container(
                  color: Colors.lightBlueAccent,
                ),
                NetwalkWidget.buildWithInput(inputState),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NetwalkWidget extends LeafRenderObjectWidget {
  final NetwalkInput input;

  NetwalkWidget(this.input, {Key? key}) : super(key: key);

  static Widget buildWithInput(NetwalkInput input) {
    NetwalkWidget netwalk = NetwalkWidget(input);
    Widget widget = netwalk;

    widget = GestureDetector(
      child: widget,
      // Absorb events
      behavior: HitTestBehavior.opaque,
      // Taps/clicks
      onTapDown: (d) => netwalk.input.onTapDown(d),
      onTapUp: (d) => netwalk.input.onTapUp(d),
      onLongPressStart: (d) => netwalk.input.onLongPressStart(d),
      onSecondaryTapUp: (d) => netwalk.input.onSecondaryTapUp(d),
      onSecondaryLongPressStart: (d) =>
          netwalk.input.onSecondaryLongPressStart(d),
      // Dragging
      dragStartBehavior: DragStartBehavior.start,
      onPanStart: (d) => netwalk.input.onDragStart(d),
      onPanUpdate: (d) => netwalk.input.onDragUpdate(d),
      onPanEnd: (d) => netwalk.input.onDragEnd(d),
    );

    widget = MouseRegion(
        child: Listener(
      child: widget,
      onPointerSignal: (e) => netwalk.input.onPointerSignal(e),
      onPointerMove: (e) => netwalk.input.onPointerMove(e),
      onPointerHover: (e) => netwalk.input.onPointerHover(e),
    ));

    widget = Focus(
      child: widget,
      autofocus: true,
      onKey: (n, e) => netwalk.input.onKey(e),
    );

    return widget;
  }

  @override
  RenderBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      child: NetwalkRenderBox(this.input),
      additionalConstraints: const BoxConstraints.expand(),
    );
  }
}
