import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearo/app/nearo_app.dart';
import 'package:nearo/core/providers/app_providers.dart';

void main() {
  testWidgets('Nearo renders sign-in screen in demo mode', (tester) async {
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
}
