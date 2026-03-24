import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_predictor/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GPAPredictorApp());
    expect(find.text('Student GPA Predictor'), findsOneWidget);
  });
}
