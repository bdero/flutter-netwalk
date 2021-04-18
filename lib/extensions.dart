import 'package:vector_math/vector_math_64.dart';

import 'package:flutter/gestures.dart';

extension NetwalkVector3 on Vector3 {
  Offset toOffset() => Offset(this.x, this.y);
}
extension NetwalkOffset on Offset {
  Vector3 toVector3() => Vector3(this.dx, this.dy, 0);
}
