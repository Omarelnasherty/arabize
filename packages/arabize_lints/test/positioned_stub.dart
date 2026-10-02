/// A minimal stand-in for `package:flutter/widgets.dart`.
const positionedStub = r'''
class Positioned {
  const Positioned({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
    Object? child,
  });
  const Positioned.fill({
    double? left,
    double? top,
    double? right,
    double? bottom,
    Object? child,
  });
}

class PositionedDirectional {
  const PositionedDirectional({
    double? start,
    double? top,
    double? end,
    double? bottom,
    double? width,
    double? height,
    Object? child,
  });
}
''';
