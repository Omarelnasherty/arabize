/// A minimal stand-in for `package:flutter/widgets.dart`.
const iconsStub = r'''
class IconData {
  const IconData(this.codePoint);
  final int codePoint;
}

class Icons {
  static const IconData chevron_left = IconData(1);
  static const IconData chevron_right = IconData(2);
  static const IconData keyboard_arrow_right_rounded = IconData(3);
  static const IconData arrow_back = IconData(4);
  static const IconData home = IconData(5);
}

class Icon {
  const Icon(this.icon, {this.matchTextDirection});
  final IconData? icon;
  final bool? matchTextDirection;
}
''';
