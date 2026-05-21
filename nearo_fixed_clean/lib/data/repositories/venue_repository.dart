import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/venue.dart';
import '../../domain/entities/venue_event.dart';

class VenueRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  VenueRepository({required this.firebaseReady})
      : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Stream<List<Venue>> watchActiveVenues() {
    if (!firebaseReady || _firestore == null) {
      return Stream<List<Venue>>.value(_demoVenues());
    }

    return _firestore
        .collection(FirebaseCollections.venues)
        .where('isActive', isEqualTo: true)
        .orderBy('liveStats.socialEnergy', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Venue.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<VenueEvent>> watchVenueEvents(String venueId) {
    if (!firebaseReady || _firestore == null) {
      final now = DateTime.now();
      return Stream<List<VenueEvent>>.value([
        VenueEvent(
          id: 'event-demo',
          venueId: venueId,
          title: 'Neon Social Night',
          description: 'Low-pressure social prompts, lounge music, and live Nearo stats.',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 4)),
          vibe: 'Social',
          music: 'Jazz / House',
          crowdLevel: 72,
          waitTime: '10 min',
          createdAt: now,
        ),
      ]);
    }
    return _firestore
        .collection(FirebaseCollections.venueEvents)
        .where('venueId', isEqualTo: venueId)
        .where('endsAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('endsAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VenueEvent.fromMap(doc.data(), doc.id)).toList());
  }

  List<Venue> _demoVenues() {
    return const [
      Venue(
        id: 'venue-1',
        name: 'Mono Lounge',
        description: 'Lounge cocktail bar with warm light, soft music, and a very social crowd.',
        address: '42 Night Ave',
        latitude: 41.7151,
        longitude: 44.8271,
        wifiHashes: ['demo-venue-hash'],
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
        photoUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b',
        activeEventIds: ['event-demo'],
      ),
      Venue(
        id: 'venue-2',
        name: 'Neon District',
        description: 'High-energy club with DJs, LED visuals and a full dance floor.',
        address: '188 Electric Street',
        latitude: 41.7134,
        longitude: 44.8015,
        wifiHashes: ['demo-venue-hash-2'],
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
        photoUrl: 'https://images.unsplash.com/photo-1571266028243-d220c9c3b2d2',
      ),
    ];
  }
}
