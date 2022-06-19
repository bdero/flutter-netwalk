import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'extensions.dart';

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

class NetwalkInput {
  static const double MIN_SCALE = 0.2;
  static const double MAX_SCALE = 5;

  // Always assume a size of 100
  static const double PIECE_SIZE = 100;

  late Matrix4 _transform;

  Matrix4 get transform => _transform;

  late final Vector3 _boardSize;
  get boardSize => (_boardSize * _transform.getMaxScaleOnAxis()).toOffset();
  Offset _boardCenter = Offset.zero;

  set screenSize(Size o) => _boardCenter = Offset(o.width / 2, o.height / 2);

  // Used in conjunction with key inputs.
  Offset _lastKnownMousePosition = Offset.zero;
  ParabolicEase? _flick;

  // Snapshot of the board transform origin for calculating velocity each tick.
  Vector3 _tickBoardOrigin = Vector3.zero();
  Vector3 _originVelocity = Vector3.zero();

  // Whenever the board wraps around, this value is flipped on to prevent
  // the velocity from being recalculated.
  bool _boardWrappedThisFrame = false;

  NetwalkInput(int boardSizeX, int boardSizeY) {
    _boardSize = Vector3(boardSizeX.toDouble() * PIECE_SIZE,
        boardSizeY.toDouble() * PIECE_SIZE, 0);
    _transform = Matrix4.translation(-_boardSize / 2);
  }

  // Interpret raw inputs as game actions.

  onTapDown(TapDownDetails d) => _startTap();

  onTapUp(TapUpDetails d) => _rotatePiece(d.localPosition - _boardCenter, true);

  onLongPressStart(LongPressStartDetails d) =>
      _lockPiece(d.localPosition - _boardCenter);

  onSecondaryTapUp(TapUpDetails d) =>
      _lockPiece(d.localPosition - _boardCenter);

  onSecondaryLongPressStart(LongPressStartDetails d) =>
      _lockPiece(d.localPosition - _boardCenter);

  onDragStart(DragStartDetails d) => _startDrag(d.localPosition - _boardCenter);

  onDragUpdate(DragUpdateDetails d) => _continueDrag(d.delta);

  onDragEnd(DragEndDetails d) => _releaseDrag();

  onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      _scroll(e.localPosition - _boardCenter, e.scrollDelta.dy);
    }
  }

  onPointerMove(PointerMoveEvent e) {
    _lastKnownMousePosition = e.localPosition - _boardCenter;
  }

  onPointerHover(PointerHoverEvent e) {
    _lastKnownMousePosition = e.localPosition - _boardCenter;
  }

  onKey(RawKeyEvent e) {
    if (e is RawKeyDownEvent) {
      if (e.logicalKey == LogicalKeyboardKey.keyA ||
          e.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _rotatePiece(_lastKnownMousePosition, false);
        return KeyEventResult.handled;
      }
      if (e.logicalKey == LogicalKeyboardKey.keyD ||
          e.logicalKey == LogicalKeyboardKey.arrowRight) {
        _rotatePiece(_lastKnownMousePosition, true);
        return KeyEventResult.handled;
      }
      if (e.logicalKey == LogicalKeyboardKey.space) {
        _lockPiece(_lastKnownMousePosition);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void tick(double dt) {
    Vector3 boardOrigin = _transform.getTranslation();
    // Compute the velocity of the board origin.
    if (dt > 0 && !_boardWrappedThisFrame) {
      _originVelocity =
          (boardOrigin - _tickBoardOrigin) / dt * 0.5 + _originVelocity * 0.5;
    }
    _tickBoardOrigin = boardOrigin;
    _boardWrappedThisFrame = false;

    // Apply flick offset if occurring.
    if (_flick != null) {
      double dv = _flick!.tick(dt);
      _applyTranslation(_originVelocity.normalized() * dv);
      if (_flick!.complete()) {
        _flick = null;
      }
    }
  }

  // Internal actions, typically called by input.

  _rotatePiece(Offset position, bool clockwise) {
    var pieceCoordinates =
        _toBoardCoordinate(_toBoardSpace(position.toVector3()));
    print("rotate piece " +
        (clockwise ? "" : "counter-") +
        "clockwise at " +
        pieceCoordinates.toString());
  }

  _lockPiece(Offset position) {
    var pieceCoordinates =
        _toBoardCoordinate(_toBoardSpace(position.toVector3()));
    print("lock piece at " + pieceCoordinates.toString());
  }

  _startTap() {
    _flick = null;
  }

  _startDrag(Offset position) {
    _flick = null;
  }

  _continueDrag(Offset delta) {
    _applyTranslation(delta.toVector3());
  }

  _releaseDrag() {
    double flickVelocity = _originVelocity.length;
    // Decelerate slower for faster flicks.
    _flick = ParabolicEase(flickVelocity, 10000 / flickVelocity + 3000);
  }

  _scroll(Offset position, double amount) {
    _applyScale(position.toVector3(), pow(e, -amount / 2000).toDouble());
  }

  _applyTranslation(Vector3 translation) {
    translation = translation / _transform.getMaxScaleOnAxis();
    _transform.translate(translation.x, translation.y, translation.z);

    _boundTranslation();
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

    _boundTranslation();
  }

  _boundTranslation() {
    Vector3 position = _transform.getTranslation();
    _transform.setTranslation(Vector3.zero());
    Matrix4 toBoardSpace = Matrix4.inverted(_transform);
    Vector3 boardPosition = toBoardSpace.transform3(position) + _boardSize;

    // Evil hack alert: If the board wraps, flip on a special flag that prevents
    // the velocity from being recalculated next frame. ¯\_(ツ)_/¯
    if (boardPosition.x < 0 ||
        boardPosition.x >= _boardSize.x ||
        boardPosition.y < 0 ||
        boardPosition.y >= _boardSize.y) {
      _boardWrappedThisFrame = true;
    }

    // Bask in the glory of Dart's actual Euclidean modulo!
    boardPosition.x = boardPosition.x % _boardSize.x;
    boardPosition.y = boardPosition.y % _boardSize.y;
    _transform
        .setTranslation(_transform.transform3(boardPosition - _boardSize));
  }

  Vector3 _toBoardSpace(Vector3 widgetPosition) =>
      Matrix4.inverted(_transform).transform3(widgetPosition);

  Point<int> _toBoardCoordinate(Vector3 boardSpacePosition) => Point(
      ((boardSpacePosition.x % _boardSize.x) / PIECE_SIZE).floor(),
      ((boardSpacePosition.y % _boardSize.y) / PIECE_SIZE).floor());
}
