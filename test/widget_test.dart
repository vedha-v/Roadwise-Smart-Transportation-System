import 'package:flutter_test/flutter_test.dart';
import 'package:roadwise/app/app.dart';

void main() {
  testWidgets('RoadWise app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RoadWiseApp());

    expect(find.text('RoadWise'), findsOneWidget);
  });
}