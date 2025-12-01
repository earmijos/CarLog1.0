// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:carlog/main.dart';

void main() {
  testWidgets('CarLog app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CarLogApp());

    // Verify that the VIN input screen loads
    expect(find.text('CarLog'), findsOneWidget);
    expect(find.text('Enter Vehicle VIN'), findsOneWidget);
  });
}
