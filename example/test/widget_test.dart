import 'package:arabize_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the title', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('arabize'), findsOneWidget);
  });
}
