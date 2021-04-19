import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:netwalk/netwalk_controller.dart';

class NetwalkRenderBox extends RenderBox {
  final NetwalkController _controller;
  late Ticker _ticker;
  Duration _previousTime = Duration.zero;

  NetwalkRenderBox(this._controller) {
    _ticker = Ticker(_tick);
  }

  void _tick(Duration currentTime) {
    final dt = (_previousTime == Duration.zero
                ? Duration.zero
                : currentTime - _previousTime)
            .inMilliseconds /
        Duration.millisecondsPerSecond;
    _previousTime = currentTime;

    _controller.tick(dt);

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
  Size computeDryLayout(BoxConstraints constraints) {
    _controller.screenSize = constraints.biggest;
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _controller.paint(context, offset, size);
  }
}
