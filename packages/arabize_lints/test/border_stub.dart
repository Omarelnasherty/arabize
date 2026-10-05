/// A minimal stand-in for `package:flutter/painting.dart`.
const borderStub = r'''
class BorderSide {
  const BorderSide();
}

class Border {
  const Border({
    BorderSide top = const BorderSide(),
    BorderSide right = const BorderSide(),
    BorderSide bottom = const BorderSide(),
    BorderSide left = const BorderSide(),
  });
  const Border.symmetric({
    BorderSide vertical = const BorderSide(),
    BorderSide horizontal = const BorderSide(),
  });
}

class BorderDirectional {
  const BorderDirectional({
    BorderSide top = const BorderSide(),
    BorderSide start = const BorderSide(),
    BorderSide end = const BorderSide(),
    BorderSide bottom = const BorderSide(),
  });
}

class Radius {
  const Radius.circular(double radius);
}

class BorderRadius {
  const BorderRadius.all(Radius radius);
  const BorderRadius.vertical({Radius top = const Radius.circular(0), Radius bottom = const Radius.circular(0)});
  const BorderRadius.horizontal({Radius left = const Radius.circular(0), Radius right = const Radius.circular(0)});
  const BorderRadius.only({
    Radius topLeft = const Radius.circular(0),
    Radius topRight = const Radius.circular(0),
    Radius bottomLeft = const Radius.circular(0),
    Radius bottomRight = const Radius.circular(0),
  });
}

class BorderRadiusDirectional {
  const BorderRadiusDirectional.only({
    Radius topStart = const Radius.circular(0),
    Radius topEnd = const Radius.circular(0),
    Radius bottomStart = const Radius.circular(0),
    Radius bottomEnd = const Radius.circular(0),
  });
}
''';
