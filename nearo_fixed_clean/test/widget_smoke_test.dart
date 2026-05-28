import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearo/app/nearo_app.dart';
import 'package:nearo/core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Nearo renders sign-in screen in demo mode', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseReadyProvider.overrideWithValue(false)],
        child: const NearoApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Nearo'), findsWidgets);
    expect(find.text('Continue in demo mode'), findsOneWidget);
  });

  testWidgets('Nearo switches sign-in copy to Georgian', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseReadyProvider.overrideWithValue(false)],
        child: const NearoApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('ქართული'));
    await tester.pumpAndSettle();

    expect(find.text('დემო რეჟიმით გაგრძელება'), findsOneWidget);
  });
}
