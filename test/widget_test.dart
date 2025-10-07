// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:educanexo360_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that app loads
    expect(find.text('EDUCANEXO360'), findsOneWidget);
    expect(find.text('Tu colegio en tus manos'), findsOneWidget);
  });
}
