import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/venue.dart';

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

  List<Venue> _demoVenues() {
    return const [
      Venue(
        id: 'venue-1',
        name: 'The Velvet Lounge',
        description: 'Upscale cocktail lounge with live jazz and calm conversations.',
        address: '42 Night Ave',
        latitude: 41.7151,
        longitude: 44.8271,
        wifiHashes: ['demo-venue-hash'],
        liveStats: VenueLiveStats(
          activeUsers: 34,
          socialEnergy: 72,
          capacityPercent: 65,
          averageAge: 27,
        ),
        atmosphere: VenueAtmosphere.upscale,
        musicType: 'Jazz',
        rating: 4.7,
        priceTier: 3,
        hours: '20:00 - 03:00',
        tags: ['cocktails', 'jazz', 'rooftop'],
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
        ),
        atmosphere: VenueAtmosphere.intense,
        musicType: 'EDM',
        rating: 4.4,
        priceTier: 2,
        hours: '22:00 - 05:00',
        tags: ['dance', 'dj', 'club'],
      ),
    ];
  }
}
