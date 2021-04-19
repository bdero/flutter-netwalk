import 'package:netwalk/netwalk_graphics.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'netwalk_input.dart';
import 'netwalk_widget.dart';

class NetwalkController {
  late final NetwalkInput _input;
  final NetwalkGraphics _graphics = NetwalkGraphics(10, 16, 22, 100, 10, 10);

  NetwalkController(int boardWidth, int boardHeight) {
    _input = NetwalkInput(10, 10);
  }

  set screenSize(Size o) => _input.screenSize = o;

  void tick(double dt) => _input.tick(dt);

  Widget buildWidget() {
    NetwalkWidget netwalk = NetwalkWidget(this);
    Widget widget = netwalk;

    widget = GestureDetector(
      child: widget,
      // Absorb events
      behavior: HitTestBehavior.opaque,
      // Taps/clicks
      onTapDown: (d) => _input.onTapDown(d),
      onTapUp: (d) => _input.onTapUp(d),
      onLongPressStart: (d) => _input.onLongPressStart(d),
      onSecondaryTapUp: (d) => _input.onSecondaryTapUp(d),
      onSecondaryLongPressStart: (d) =>
          _input.onSecondaryLongPressStart(d),
      // Dragging
      dragStartBehavior: DragStartBehavior.start,
      onPanStart: (d) => _input.onDragStart(d),
      onPanUpdate: (d) => _input.onDragUpdate(d),
      onPanEnd: (d) => _input.onDragEnd(d),
    );

    widget = MouseRegion(
        child: Listener(
      child: widget,
      onPointerSignal: (e) => _input.onPointerSignal(e),
      onPointerMove: (e) => _input.onPointerMove(e),
      onPointerHover: (e) => _input.onPointerHover(e),
    ));

    widget = Focus(
      child: widget,
      autofocus: true,
      onKey: (n, e) => _input.onKey(e),
    );

    return widget;
  }

  void paint(PaintingContext context, Offset offset, Size size) {
    var transform = _input.transform.storage;
    Offset boardSize = _input.boardSize;
    int offsetX = (size.width / boardSize.dx).ceil();
    int offsetY = (size.height / boardSize.dy).ceil();

    context.canvas.save();
    context.canvas
        .translate(offset.dx + size.width / 2, offset.dy + size.height / 2);

    var paint = Paint();
    paint.isAntiAlias = false;
    for (int x = -offsetX; x <= offsetX; x++) {
      for (int y = -offsetY; y <= offsetY; y++) {
        context.canvas.save();
        context.canvas.translate(x * boardSize.dx, y * boardSize.dy);
        context.canvas.transform(transform);
        _graphics.paintAtlas(context.canvas);
        context.canvas.restore();
      }
    }
    context.canvas.restore();
  }
}
