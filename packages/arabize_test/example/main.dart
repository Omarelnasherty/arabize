import 'package:arabize_test/arabize_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgetsBothDirections('label is visible', () => const Text('hello'), (
    tester,
    direction,
  ) async {
    expect(find.text('hello'), findsOneWidget);
  });
}
