import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'netwalk_graphics.dart';

// Renders the Netwalk game board.
class NetwalkRenderBox extends RenderBox {
  late Ticker _ticker;
  Duration _previousTime = Duration.zero;
  NetwalkGraphics gfx = NetwalkGraphics(10, 16, 22, 100);

  NetwalkRenderBox() {
    _ticker = Ticker(_tick);
  }

  void _tick(Duration currentTime) {
    final dt = (_previousTime == Duration.zero
                ? Duration.zero
                : currentTime - _previousTime)
            .inMilliseconds /
        Duration.millisecondsPerSecond;
    _previousTime = currentTime;

    markNeedsPaint();
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _ticker.start();
  }

  @override
  void detach() {
    super.detach();
    _ticker.stop();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);
    gfx.PaintAtlas(context.canvas);
    context.canvas.restore();
  }
}
