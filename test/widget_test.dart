import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roambite/main.dart';
import 'package:roambite/providers/auth_provider.dart';
import 'package:roambite/providers/theme_provider.dart';

void main() {
  testWidgets('RoamBite app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const RoamBiteApp(),
      ),
    );
    expect(find.byType(RoamBiteApp), findsOneWidget);
  });
}

