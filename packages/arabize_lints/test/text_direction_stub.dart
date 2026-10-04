/// A minimal stand-in for `package:flutter/painting.dart`.
const textDirectionStub = r'''
enum TextDirection { rtl, ltr }

class Directionality {
  const Directionality({required this.textDirection, this.child});
  final TextDirection textDirection;
  final Object? child;
}

class Other {
  const Other({this.direction});
  final TextDirection? direction;
}
''';
