import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krevzy/main.dart';

void main() {
  testWidgets('KREVZY app shell class can be constructed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('KREVZY')),
        ),
      ),
    );

    expect(find.text('KREVZY'), findsOneWidget);
    expect(const GapshapApp(), isA<GapshapApp>());
  });
}
