import 'package:arabize_test/arabize_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pumpRtl defaults to right-to-left', (tester) async {
    late TextDirection seen;
    await pumpRtl(
      tester,
      Builder(
        builder: (context) {
          seen = Directionality.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(seen, TextDirection.rtl);
  });

  testWidgets('pumpRtl accepts a direction', (tester) async {
    late TextDirection seen;
    await pumpRtl(
      tester,
      Builder(
        builder: (context) {
          seen = Directionality.of(context);
          return const SizedBox();
        },
      ),
      textDirection: TextDirection.ltr,
    );
    expect(seen, TextDirection.ltr);
  });

  testWidgetsBothDirections(
    'start padding lands on the leading side',
    () => const Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(key: Key('box'), width: 10, height: 10),
    ),
    (tester, direction) async {
      final left = tester.getTopLeft(find.byKey(const Key('box'))).dx;
      expect(left, direction == TextDirection.ltr ? 0 : 800 - 10);
    },
  );
}
