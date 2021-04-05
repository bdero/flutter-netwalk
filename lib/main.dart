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
      home: GameView(title: 'Large'),
    );
  }
}

class GameView extends StatefulWidget {
  NetwalkInput gameInput = NetwalkInput();

  GameView({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    Widget gameWidget = _NetwalkWidget(widget.gameInput);

    gameWidget = GestureDetector(
      child: gameWidget,
      // Absorb events
      behavior: HitTestBehavior.opaque,
      // Taps/clicks
      onTapDown: (d) => widget.gameInput.onTapDown(d),
      onTapUp: (d) => widget.gameInput.onTapUp(d),
      onLongPressStart: (d) => widget.gameInput.onLongPressStart(d),
      onSecondaryTapUp: (d) => widget.gameInput.onSecondaryTapUp(d),
      onSecondaryLongPressStart: (d) =>
          widget.gameInput.onSecondaryLongPressStart(d),
      // Dragging
      dragStartBehavior: DragStartBehavior.start,
      onPanStart: (d) => widget.gameInput.onDragStart(d),
      onPanUpdate: (d) => widget.gameInput.onDragUpdate(d),
      onPanEnd: (d) => widget.gameInput.onDragEnd(d),
    );

    gameWidget = MouseRegion(
      child: Listener(
        child: gameWidget,
        onPointerSignal: (e) => widget.gameInput.onPointerSignal(e),
        onPointerMove: (e) => widget.gameInput.onPointerMove(e),
        onPointerHover: (e) => widget.gameInput.onPointerHover(e),
      )
    );

    gameWidget = Focus(
      child: gameWidget,
      autofocus: true,
      onKey: (n, e) => widget.gameInput.onKey(e),
    );

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
                gameWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NetwalkWidget extends LeafRenderObjectWidget {
  final NetwalkInput gameInput;

  const _NetwalkWidget(this.gameInput);

  @override
  RenderBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      child: NetwalkRenderBox(this.gameInput),
      additionalConstraints: const BoxConstraints.expand(),
    );
  }
}
