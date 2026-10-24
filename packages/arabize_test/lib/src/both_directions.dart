import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_rtl.dart';

/// Runs [body] twice, once for left-to-right and once for right-to-left.
///
/// The widget is built with [build] and pumped in the matching direction
/// before [body] runs. The test names get an `(ltr)` or `(rtl)` suffix.
void testWidgetsBothDirections(
  String description,
  Widget Function() build,
  Future<void> Function(WidgetTester tester, TextDirection direction) body, {
  bool skip = false,
}) {
  for (final direction in TextDirection.values) {
    testWidgets('$description (${direction.name})', (tester) async {
      await pumpRtl(tester, build(), textDirection: direction);
      await body(tester, direction);
    }, skip: skip);
  }
}
