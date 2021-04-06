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
  static const double MIN_SCALE = 0.2;
  static const double MAX_SCALE = 5;

  Offset _lastKnownMousePosition = Offset.zero;
  ParabolicEase? flick;

  Vector3 _tickBoardOrigin = Vector3.zero();
  Vector3 _originVelocity = Vector3.zero();
  double _boardScale = 1;
  Matrix4 _transform = Matrix4.identity();

  Matrix4 get transform => _transform;

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
      _scroll(e.localPosition, e.scrollDelta.dy);
    }
  }

  onPointerMove(PointerMoveEvent e) {
    _lastKnownMousePosition = e.localPosition;
  }

  onPointerHover(PointerHoverEvent e) {
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
    if (dt > 0) {
      Vector3 boardOrigin = _transform.getTranslation();
      _originVelocity =
          (boardOrigin - _tickBoardOrigin) / dt * 0.5 + _originVelocity * 0.5;
      _tickBoardOrigin = boardOrigin;
    }

    // Apply flick offset if occurring.
    if (flick != null) {
      double dv = flick!.tick(dt);
      _applyTranslation(_originVelocity.normalized() * dv);
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
    flick = null;
  }

  _continueDrag(Offset delta) {
    _applyTranslation(vector3FromOffset(delta));
  }

  _releaseDrag() {
    double flickVelocity = _originVelocity.length;
    // Decelerate slower for faster flicks.
    flick = ParabolicEase(flickVelocity, 100000 / flickVelocity + 300);
  }

  _scroll(Offset position, double amount) {
    _applyScale(vector3FromOffset(position), pow(e, -amount / 2000).toDouble());
  }

  _lockPiece(Offset position) {
    print("lock piece at " + position.toString());
  }

  _applyTranslation(Vector3 translation) {
    translation = translation / _transform.getMaxScaleOnAxis();
    _transform.translate(translation.x, translation.y, translation.z);
  }

  _applyScale(Vector3 screenPosition, double scale) {
    Vector3 boardPosition =
        Matrix4.inverted(_transform).transform3(screenPosition);

    double currentScale = _transform.getMaxScaleOnAxis();
    double scaleDestination =
        max(MIN_SCALE, min(MAX_SCALE, _transform.getMaxScaleOnAxis() * scale));
    double deltaScale = scaleDestination / currentScale;

    _transform.translate(boardPosition.x, boardPosition.y, boardPosition.z);
    _transform.scale(deltaScale);
    _transform.translate(-boardPosition.x, -boardPosition.y, -boardPosition.z);
  }
}
