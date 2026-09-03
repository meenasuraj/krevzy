import 'package:flutter_test/flutter_test.dart';
import 'package:gapshap/main.dart';

void main() {
  testWidgets('Gapshap app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GapshapApp());

    expect(find.text('GAPSHAP'), findsOneWidget);
  });
}
