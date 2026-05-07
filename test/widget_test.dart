import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:listd/main.dart';

void main() {
  testWidgets('Listd app launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ListdApp()));

    // Verify that the app starts.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
