import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/signal_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/venue_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/nearo_user.dart';
import '../../domain/entities/signal.dart';
import '../../domain/entities/venue.dart';
import '../services/notification_service.dart';
import '../services/proximity_service.dart';
import '../services/report_service.dart';

final firebaseReadyProvider = Provider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(firebaseReady: ref.watch(firebaseReadyProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firebaseReady: ref.watch(firebaseReadyProvider));
});

final signalRepositoryProvider = Provider<SignalRepository>((ref) {
  return SignalRepository(firebaseReady: ref.watch(firebaseReadyProvider));
});

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository(firebaseReady: ref.watch(firebaseReadyProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firebaseReady: ref.watch(firebaseReadyProvider));
});

final proximityServiceProvider = Provider<ProximityService>((ref) {
  return ProximityService();
});

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(firebaseReady: ref.watch(firebaseReadyProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(firebaseReady: ref.watch(firebaseReadyProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(
    authRepository: ref.watch(authRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  StreamSubscription<AppUser?>? _subscription;

  AuthController({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        super(const AsyncLoading()) {
    _subscription = _authRepository.authStateChanges().listen(
      (user) => state = AsyncData(user),
      onError: (Object error, StackTrace stackTrace) => state = AsyncError(error, stackTrace),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.signIn(email: email, password: password);
      await _userRepository.ensureUserProfile(appUser: user);
      state = AsyncData(user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required int age,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _userRepository.ensureUserProfile(appUser: user, age: age);
      state = AsyncData(user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> continueAsDemo() async {
    state = const AsyncData(AppUser.demo);
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncData(null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final currentUserProfileProvider = StreamProvider<NearoUser?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream<NearoUser?>.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
});

final nearbyUsersProvider = StreamProvider<List<NearoUser>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null) return Stream<List<NearoUser>>.value(const []);
  return ref.watch(userRepositoryProvider).watchNearbyUsers(
        currentUserId: user.uid,
        wifiHash: profile?.wifiHash,
      );
});

final activeVenuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueRepositoryProvider).watchActiveVenues();
});

final incomingSignalsProvider = StreamProvider<List<Signal>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream<List<Signal>>.value(const []);
  return ref.watch(signalRepositoryProvider).watchIncomingSignals(user.uid);
});

final matchesProvider = StreamProvider<List<Match>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream<List<Match>>.value(const []);
  return ref.watch(signalRepositoryProvider).watchMatches(user.uid);
});
