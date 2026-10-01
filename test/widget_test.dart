import 'package:flutter_test/flutter_test.dart';
import 'package:roadwise/app/app.dart';

void main() {
  testWidgets('Explore screen renders the smart restaurant search UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RoadWiseApp());

    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Search restaurants or places'), findsOneWidget);
    expect(find.text('Recommended for you'), findsOneWidget);
  });
}
