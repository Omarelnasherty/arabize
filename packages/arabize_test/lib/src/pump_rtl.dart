import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [widget] inside a [Directionality] with the given [textDirection].
///
/// Defaults to right-to-left. The widget is wrapped in a [MediaQuery] so it
/// can be used without a [MaterialApp].
Future<void> pumpRtl(
  WidgetTester tester,
  Widget widget, {
  TextDirection textDirection = TextDirection.rtl,
  Duration? duration,
}) {
  return tester.pumpWidget(
    Directionality(
      textDirection: textDirection,
      child: MediaQuery(data: const MediaQueryData(), child: widget),
    ),
    duration: duration,
  );
}
