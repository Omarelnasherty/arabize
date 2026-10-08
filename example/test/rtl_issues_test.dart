import 'package:arabize_example/rtl_issues.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds the screen with the lint examples', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RtlIssues())),
    );
    expect(find.text('arabize'), findsOneWidget);
  });
}
