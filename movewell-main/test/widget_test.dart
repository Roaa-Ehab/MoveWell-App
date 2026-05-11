import 'package:flutter_test/flutter_test.dart';
import 'package:movewell/main.dart';

void main() {
  testWidgets('MoveWell app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MoveWellApp());
    expect(find.text('Recover Better. Move Smarter.'), findsOneWidget);
  });
}