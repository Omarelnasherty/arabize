import 'package:arabize_test/arabize_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testGoldensBothDirections(
    'arabic row',
    () => const Padding(
      padding: EdgeInsetsDirectional.only(start: 16, top: 16),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: ColoredBox(color: Color(0xFF1565C0)),
          ),
          SizedBox(width: 8),
          Text('مرحبا بالعالم'),
        ],
      ),
    ),
    name: 'arabic_row',
  );

  testWidgets('loadArabicFont can be called twice', (tester) async {
    await loadArabicFont();
    await loadArabicFont();
  });
}
