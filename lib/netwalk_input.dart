import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/raw_keyboard.dart';

// Self contained parabola parameterized by velocity and friction values.
class ParabolicEase {
  double _velocity;
  double _friction;
  double _time = 0;
  late double _maxTime;

  double _value = 0;

  double get value => _value;

  ParabolicEase(this._velocity, this._friction) {
    _maxTime = _velocity / _friction / 2;
  }

  // Returns the value delta.
  double tick(double dt) {
    _time = min(_maxTime, _time + dt);
    double oldValue = _value;
    _value = -_friction * _time * _time + _velocity * _time;
    return _value - oldValue;
  }

  bool complete() => _time >= _maxTime;
}

Vector3 vector3FromOffset(Offset offset) {
  return Vector3(offset.dx, offset.dy, 0);
}

class NetwalkInput {
  Offset _lastKnownMousePosition = Offset.zero;
  ParabolicEase? flick;

  Vector3 _boardOrigin = Vector3.zero();
  Vector3 _tickBoardOrigin = Vector3.zero();
  Vector3 _originVelocity = Vector3.zero();
  double _boardScale = 1;

  Matrix4 get transform => Matrix4.compose(
      _boardOrigin, Quaternion.identity(), Vector3.all(_boardScale));

  // Interpret raw inputs as internal actions.

  onTapDown(TapDownDetails d) => _startTap();

  onTapUp(TapUpDetails d) => _rotatePiece(d.localPosition, true);

  onLongPressStart(LongPressStartDetails d) => _lockPiece(d.localPosition);

  onSecondaryTapUp(TapUpDetails d) => _lockPiece(d.localPosition);

  onSecondaryLongPressStart(LongPressStartDetails d) =>
      _lockPiece(d.localPosition);

  onDragStart(DragStartDetails d) => _startDrag(d.localPosition);

  onDragUpdate(DragUpdateDetails d) => _continueDrag(d.delta);

  onDragEnd(DragEndDetails d) => _releaseDrag();

  onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      print("scroll: " + e.scrollDelta.toString());
    }
  }

  onPointerMove(PointerMoveEvent e) {
    print("pointer move: " + e.localPosition.toString());
    _lastKnownMousePosition = e.localPosition;
  }

  onPointerHover(PointerHoverEvent e) {
    print("pointer hover: " + e.localPosition.toString());
    _lastKnownMousePosition = e.localPosition;
  }

  onKey(RawKeyEvent e) {
    if (e is RawKeyDownEvent) {
      if (e.logicalKey == LogicalKeyboardKey.keyA ||
          e.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _rotatePiece(_lastKnownMousePosition, false);
        return true;
      }
      if (e.logicalKey == LogicalKeyboardKey.keyD ||
          e.logicalKey == LogicalKeyboardKey.arrowRight) {
        _rotatePiece(_lastKnownMousePosition, true);
        return true;
      }
      if (e.logicalKey == LogicalKeyboardKey.space) {
        _lockPiece(_lastKnownMousePosition);
        return true;
      }
    }
    return false;
  }

  void tick(double dt) {
    // Compute the velocity of the board origin.
    if (dt > 0)
      _originVelocity =
          (_boardOrigin - _tickBoardOrigin) / dt * 0.5 + _originVelocity * 0.5;
    _tickBoardOrigin = _boardOrigin;

    // Apply flick offset if occurring.
    if (flick != null) {
      double dv = flick!.tick(dt);
      _translateBoard(_originVelocity.normalized() * dv);
      if (flick!.complete()) {
        flick = null;
      }
    }
  }

  // Internal actions, typically called by input.

  _rotatePiece(Offset position, bool clockwise) {
    print("rotate piece " +
        (clockwise ? "" : "counter-") +
        "clockwise at " +
        position.toString());
  }

  _startTap() {
    flick = null;
  }

  _startDrag(Offset position) {
    print("drag start: " + position.toString());
    flick = null;
  }

  _continueDrag(Offset delta) {
    print("drag continue: " + delta.toString());
    _translateBoard(vector3FromOffset(delta));
  }

  _releaseDrag() {
    print("drag end");
    double flickVelocity = _originVelocity.length;
    // Decelerate slower for faster flicks.
    flick = ParabolicEase(flickVelocity, 100000 / flickVelocity + 300);
  }

  _lockPiece(Offset position) {
    print("lock piece at " + position.toString());
  }

  _translateBoard(Vector3 translation) {
    _boardOrigin += translation;
  }
}
