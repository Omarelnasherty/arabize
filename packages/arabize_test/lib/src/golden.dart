import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_rtl.dart';

/// The family name of the bundled Arabic font.
const String arabicTestFontFamily = 'Amiri';

/// Registers the bundled Amiri font so Arabic text renders with real glyphs
/// in tests. Safe to call more than once.
Future<void> loadArabicFont() async {
  const path = 'fonts/Amiri-Regular.ttf';
  ByteData data;
  try {
    data = await rootBundle.load('packages/arabize_test/lib/$path');
  } on FlutterError {
    data = await rootBundle.load('lib/$path');
  }
  await (FontLoader(arabicTestFontFamily)..addFont(Future.value(data))).load();
}

/// Compares [build] against golden files in both text directions.
///
/// Files are named `<name>.ltr.png` and `<name>.rtl.png`. The Arabic font is
/// loaded and set as the default text style, and the widget is sized to
/// [size].
void testGoldensBothDirections(
  String description,
  Widget Function() build, {
  required String name,
  Size size = const Size(400, 200),
}) {
  for (final direction in TextDirection.values) {
    testWidgets('$description (${direction.name})', (tester) async {
      await loadArabicFont();
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpRtl(
        tester,
        RepaintBoundary(
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: arabicTestFontFamily,
                fontSize: 24,
                color: Color(0xFF000000),
              ),
              child: build(),
            ),
          ),
        ),
        textDirection: direction,
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/$name.${direction.name}.png'),
      );
    });
  }
}
