import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wizi_learn/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app starts', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Basic check: verify if the app has started by checking for a common widget or text
      // You can replace this with a real login or splash screen check
      expect(find.byType(app.MyApp), findsOneWidget);
    });
  });
}
