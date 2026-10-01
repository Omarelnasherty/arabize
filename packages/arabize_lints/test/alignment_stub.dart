/// A minimal stand-in for `package:flutter/painting.dart`.
const alignmentStub = r'''
class Alignment {
  const Alignment(double x, double y);
  static const Alignment topLeft = Alignment(-1, -1);
  static const Alignment topCenter = Alignment(0, -1);
  static const Alignment topRight = Alignment(1, -1);
  static const Alignment centerLeft = Alignment(-1, 0);
  static const Alignment center = Alignment(0, 0);
  static const Alignment centerRight = Alignment(1, 0);
  static const Alignment bottomLeft = Alignment(-1, 1);
  static const Alignment bottomCenter = Alignment(0, 1);
  static const Alignment bottomRight = Alignment(1, 1);
}

class AlignmentDirectional {
  const AlignmentDirectional(double start, double y);
  static const AlignmentDirectional centerStart = AlignmentDirectional(-1, 0);
  static const AlignmentDirectional centerEnd = AlignmentDirectional(1, 0);
}
''';
