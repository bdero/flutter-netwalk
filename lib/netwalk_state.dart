import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/raw_keyboard.dart';

class NetwalkState {
  Offset _lastKnownMousePosition = Offset.zero;

  onTapUp(TapUpDetails d) => _rotatePiece(d.localPosition, true);

  onLongPressStart(LongPressStartDetails d) => _lockPiece(d.localPosition);

  onSecondaryTapUp(TapUpDetails d) => _lockPiece(d.localPosition);

  onSecondaryLongPressStart(LongPressStartDetails d) =>
      _lockPiece(d.localPosition);

  dragStart(DragStartDetails d) {
    print("drag start: " + d.kind.toString());
  }

  onDragUpdate(DragUpdateDetails d) {
    print("drag update: " +
        d.localPosition.toString() +
        " : " +
        d.primaryDelta.toString());
  }

  onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      print("scroll: " + e.scrollDelta.toString());
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

  _rotatePiece(Offset position, bool clockwise) {
    print("rotate piece " +
        (clockwise ? "" : "counter-") +
        "clockwise at " +
        position.toString());
  }

  _lockPiece(Offset position) {
    print("lock piece at " + position.toString());
  }
}
