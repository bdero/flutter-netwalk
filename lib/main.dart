import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'netwalk_state.dart';
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
  NetwalkState gameState = NetwalkState();

  GameView({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    Widget gameWidget = _NetwalkWidget(widget.gameState);

    gameWidget = GestureDetector(
      child: gameWidget,
      behavior: HitTestBehavior.opaque,
      // Taps/clicks
      onTapUp: (d) => widget.gameState.onTapUp(d),
      onLongPressStart: (d) => widget.gameState.onLongPressStart(d),
      onSecondaryTapUp: (d) => widget.gameState.onSecondaryTapUp(d),
      onSecondaryLongPressStart: (d) =>
          widget.gameState.onSecondaryLongPressStart(d),
      // Dragging
      dragStartBehavior: DragStartBehavior.start,
      onHorizontalDragStart: (d) => widget.gameState.dragStart(d),
      onHorizontalDragUpdate: (d) => widget.gameState.onDragUpdate(d),
      onVerticalDragStart: (d) => widget.gameState.dragStart(d),
      onVerticalDragUpdate: (d) => widget.gameState.onDragUpdate(d),
    );

    gameWidget = MouseRegion(
      child: Listener(
        child: gameWidget,
        onPointerSignal: (e) => widget.gameState.onPointerSignal(e),
        onPointerMove: (e) => widget.gameState.onPointerMove(e),
        onPointerHover: (e) => widget.gameState.onPointerHover(e),
      )
    );

    gameWidget = Focus(
      child: gameWidget,
      autofocus: true,
      onKey: (n, e) => widget.gameState.onKey(e),
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
  final NetwalkState gameState;

  const _NetwalkWidget(this.gameState);

  @override
  RenderBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      child: NetwalkRenderBox(),
      additionalConstraints: const BoxConstraints.expand(),
    );
  }
}
