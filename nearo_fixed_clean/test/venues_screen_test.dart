import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearo/core/localization/app_localizations.dart';
import 'package:nearo/core/providers/app_providers.dart';
import 'package:nearo/domain/entities/venue.dart';
import 'package:nearo/presentation/screens/venues/venues_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Spots search, filter, and favorite state work', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeVenuesProvider.overrideWith((ref) => Stream.value(_venues)),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: VenuesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Mono Lounge'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Neon');
    await tester.pumpAndSettle();

    expect(find.text('Neon District'), findsOneWidget);
    expect(find.text('Mono Lounge'), findsNothing);

    await tester.tap(find.byIcon(Icons.favorite_border).last);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('nearo.favoriteVenueIds'), contains('venue-2'));

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Party'));
    await tester.pumpAndSettle();

    expect(find.text('Neon District'), findsOneWidget);
    expect(find.text('Mono Lounge'), findsNothing);
  });
}

const _venues = [
  Venue(
    id: 'venue-1',
    name: 'Mono Lounge',
    description: 'Warm lounge with jazz and calm conversations.',
    address: '42 Night Ave',
    latitude: 41.7151,
    longitude: 44.8271,
    wifiHashes: ['mono-wifi'],
    liveStats: VenueLiveStats(
      activeUsers: 24,
      socialEnergy: 86,
      capacityPercent: 65,
      averageAge: 27,
      openUsersCount: 24,
      matchesTonight: 18,
      crowdLevel: 72,
      waitTime: '10 min',
    ),
    atmosphere: VenueAtmosphere.social,
    vibe: 'Lounge',
    musicType: 'Jazz',
    rating: 4.7,
    priceTier: 3,
    hours: '20:00 - 03:00',
    tags: ['Jazz', 'Chill', 'Romantic'],
  ),
  Venue(
    id: 'venue-2',
    name: 'Neon District',
    description: 'High-energy party club with DJs.',
    address: '188 Electric Street',
    latitude: 41.7134,
    longitude: 44.8015,
    wifiHashes: ['neon-wifi'],
    liveStats: VenueLiveStats(
      activeUsers: 91,
      socialEnergy: 94,
      capacityPercent: 88,
      averageAge: 24,
      openUsersCount: 31,
      matchesTonight: 22,
      crowdLevel: 88,
      waitTime: '15 min',
    ),
    atmosphere: VenueAtmosphere.party,
    vibe: 'Party',
    musicType: 'EDM',
    rating: 4.4,
    priceTier: 2,
    hours: '22:00 - 05:00',
    tags: ['Lively', 'Party'],
  ),
];
