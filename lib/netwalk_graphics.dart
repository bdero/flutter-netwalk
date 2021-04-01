import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

// Collection of paths that allows for conveniently manipulating multiple paths
// simultaneously. This is useful for keeping track of paths used for outline
// drawing whilst the base shapes are being built up from primitives.
class PathSet {
  List<Path> paths;
  Path lockPath;

  PathSet(Path weight1, Path weight2, Path weight3) {
    paths = new List.from({weight1, weight2, weight3}, growable: false);
    lockPath = _computeLockPath();
  }

  static PathSet combine(PathOperation op, PathSet first, PathSet second) {
    return PathSet(
        Path.combine(op, first.paths[0], second.paths[0]),
        Path.combine(op, first.paths[1], second.paths[1]),
        Path.combine(op, first.paths[2], second.paths[2]));
  }

  Path _computeLockPath() {
    return Path.combine(PathOperation.difference, paths[2], paths[1]);
  }

  PathSet rotate(double radians) {
    final mat4 = Matrix4.rotationZ(radians).storage;
    return PathSet(paths[0].transform(mat4), paths[1].transform(mat4),
        paths[2].transform(mat4));
  }
}

enum NetwalkPiece {
  straightSinglePiece,
  straightDoubleAnglePiece,
  straightDoubleAcrossPiece,
  straightTriplePiece,
  straightQuadPiece,
  arcDoubleAnglePiece,
  arcTriplePiece,
  arcQuadPiece
}

class NetwalkGraphics {
  final double pipeWidth, cutWidth, lockWidth, atlasSize;

  // Primitive paths used to build up everything else.
  PathSet _straightSeg, _arcSeg, _arcCutSeg;
  Map<NetwalkPiece, PathSet> _pieces = Map();

  NetwalkGraphics(
      this.pipeWidth, this.cutWidth, this.lockWidth, this.atlasSize) {
    _computePaths();
  }

  void PaintAtlas(Canvas canvas) {
    final paint = Paint();
    paint.color = Colors.white;
    canvas.save();
    canvas.translate(atlasSize / 2, atlasSize / 2);
    NetwalkPiece.values.forEach((v) {
      canvas.drawPath(_pieces[v].paths[0], paint);
      canvas.translate(atlasSize, 0);
    });
    canvas.restore();
    canvas.save();
    canvas.translate(atlasSize / 2, atlasSize*1.5);
    NetwalkPiece.values.forEach((v) {
      canvas.drawPath(_pieces[v].lockPath, paint);
      canvas.translate(atlasSize, 0);
    });
    canvas.restore();
  }

  void _computePaths() {
    _straightSeg = PathSet(
        _computeStraightPath(atlasSize, pipeWidth),
        _computeStraightPath(atlasSize, cutWidth),
        _computeStraightPath(atlasSize, lockWidth));
    _arcSeg = PathSet(
        _computeArcPath(0, atlasSize, pipeWidth),
        _computeArcPath(0, atlasSize, cutWidth),
        _computeArcPath(0, atlasSize, lockWidth));
    _arcCutSeg = PathSet(
        Path.combine(PathOperation.difference, _arcSeg.paths[0],
            _arcSeg.paths[1].transform(Matrix4.rotationZ(-pi / 2).storage)),
        _arcSeg.paths[1],
        _arcSeg.paths[2]);

    _pieces[NetwalkPiece.straightSinglePiece] = _straightSeg;
    _pieces[NetwalkPiece.straightDoubleAnglePiece] = PathSet.combine(
        PathOperation.union, _straightSeg, _straightSeg.rotate(pi / 2));
    _pieces[NetwalkPiece.straightDoubleAcrossPiece] = PathSet.combine(
        PathOperation.union, _straightSeg, _straightSeg.rotate(pi));
    _pieces[NetwalkPiece.straightTriplePiece] = PathSet.combine(
        PathOperation.union,
        _pieces[NetwalkPiece.straightDoubleAcrossPiece],
        _straightSeg.rotate(pi / 2));
    _pieces[NetwalkPiece.straightQuadPiece] = PathSet.combine(
        PathOperation.union,
        _pieces[NetwalkPiece.straightTriplePiece],
        _straightSeg.rotate(-pi / 2));
    _pieces[NetwalkPiece.arcDoubleAnglePiece] = _arcSeg;
    _pieces[NetwalkPiece.arcTriplePiece] = PathSet.combine(
        PathOperation.union, _arcSeg, _arcCutSeg.rotate(pi / 2));
    PathSet halfQuad = PathSet.combine(
        PathOperation.union, _arcCutSeg, _arcCutSeg.rotate(pi / 2));
    _pieces[NetwalkPiece.arcQuadPiece] =
        PathSet.combine(PathOperation.union, halfQuad, halfQuad.rotate(pi));
  }

  Path _computeStraightPath(double tileSize, double width) {
    final Path path = Path();
    path.addArc(Rect.fromCircle(center: Offset.zero, radius: width), 0, pi);
    path.lineTo(-width, -tileSize / 2);
    path.lineTo(width, -tileSize / 2);
    return path;
  }

  Path _computeArcPath(double angle, double tileSize, double width) {
    final startAngle = (angle + 1) * pi / 2;
    final center = Offset.fromDirection(
        startAngle + pi * 5 / 4, sqrt(tileSize * tileSize / 2));
    Path path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: tileSize / 2 - width),
        startAngle + pi / 2, -pi / 2);
    path.arcTo(Rect.fromCircle(center: center, radius: tileSize / 2 + width),
        startAngle, pi / 2, false);
    return path;
  }
}
