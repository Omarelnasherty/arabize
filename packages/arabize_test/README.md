# arabize_test

Flutter test helpers for running widget tests in both text directions.

```dart
import 'package:arabize_test/arabize_test.dart';

testWidgetsBothDirections('shows the back button', () => const MyPage(),
    (tester, direction) async {
  expect(find.byIcon(Icons.arrow_back), findsOneWidget);
});

testGoldensBothDirections('card', () => const MyCard(), name: 'card');
```

Goldens are written to `goldens/card.ltr.png` and `goldens/card.rtl.png` and rendered with a bundled Arabic font (Amiri), so Arabic text shows up instead of boxes. Call `loadArabicFont()` yourself if you write your own golden tests.

`pumpRtl(tester, widget)` pumps a single widget in RTL.

Part of [arabize](https://github.com/Omarelnasherty/arabize).
