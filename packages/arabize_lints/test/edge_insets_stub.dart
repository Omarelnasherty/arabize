/// A minimal stand-in for `package:flutter/painting.dart`.
const edgeInsetsStub = r'''
class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
  const EdgeInsets.only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  });
  const EdgeInsets.fromLTRB(double left, double top, double right, double bottom);
}

class EdgeInsetsDirectional {
  const EdgeInsetsDirectional.only({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  });
  const EdgeInsetsDirectional.fromSTEB(
    double start,
    double top,
    double end,
    double bottom,
  );
}
''';
