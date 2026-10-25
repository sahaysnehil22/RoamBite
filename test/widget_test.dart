import 'package:flutter_test/flutter_test.dart';
import 'package:roambite/main.dart';

void main() {
  testWidgets('RoamBite app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RoamBiteApp());
    expect(find.byType(RoamBiteApp), findsOneWidget);
  });
}
