import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/contact_reveal_repository.dart';
import '../../data/repositories/signal_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/venue_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/connection.dart';
import '../../domain/entities/contact_reveal.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/icebreaker.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/nearo_user.dart';
import '../../domain/entities/signal.dart';
import '../../domain/entities/venue.dart';
import '../../domain/entities/venue_event.dart';
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

final contactRevealRepositoryProvider = Provider<ContactRevealRepository>((ref) {
  return ContactRevealRepository(firebaseReady: ref.watch(firebaseReadyProvider));
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
    ref: ref,
    authRepository: ref.watch(authRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref ref;
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  StreamSubscription<AppUser?>? _subscription;

  AuthController({
    required this.ref,
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

  Future<PhoneVerificationSession> requestSmsCode({
    required String phoneNumber,
    int? resendToken,
  }) {
    return _authRepository.requestSmsCode(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
    );
  }

  Future<void> verifySmsCode({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.verifySmsCode(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );
      await _userRepository.ensureUserProfile(appUser: user);
      state = AsyncData(user);
      _syncFcmToken(user.uid);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> completeOnboarding({
    required AppUser appUser,
    required String nickname,
    required int age,
    required String photoUrl,
    String? bio,
    String? mood,
    UserSocials socials = const UserSocials(),
  }) async {
    await _userRepository.completeOnboarding(
      uid: appUser.uid,
      phoneNumber: appUser.phoneNumber,
      nickname: nickname,
      age: age,
      photoUrl: photoUrl,
      bio: bio,
      mood: mood,
      socials: socials,
    );
    ref.invalidate(currentUserProfileProvider);
  }

  Future<void> continueAsDemo() async {
    state = const AsyncData(AppUser.demo);
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncData(null);
  }

  Future<void> _syncFcmToken(String uid) async {
    final token = _authRepository.firebaseReady
        ? await ref.read(notificationServiceProvider).requestAndGetToken()
        : null;
    if (token != null) {
      await _userRepository.updateFcmToken(uid: uid, token: token);
    }
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
  if (user == null || profile?.visible == false) return Stream<List<NearoUser>>.value(const []);
  return ref.watch(userRepositoryProvider).watchNearbyUsers(
        currentUserId: user.uid,
        wifiHash: profile?.wifiHash,
        blockedUsers: profile?.blockedUsers ?? const [],
      );
});

final activeVenuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueRepositoryProvider).watchActiveVenues();
});

final venueEventsProvider = StreamProvider.family<List<VenueEvent>, String>((ref, venueId) {
  return ref.watch(venueRepositoryProvider).watchVenueEvents(venueId);
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

final connectionProvider = StreamProvider.family<Connection?, String>((ref, connectionId) {
  return ref.watch(signalRepositoryProvider).watchConnection(connectionId);
});

final contactRevealsProvider = StreamProvider.family<List<ContactReveal>, String>((ref, matchId) {
  return ref.watch(contactRevealRepositoryProvider).watchMatchReveals(matchId);
});

final conversationProvider = StreamProvider.family<Conversation?, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).watchConversation(conversationId);
});

final icebreakersProvider = StreamProvider<List<Icebreaker>>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  return ref.watch(chatRepositoryProvider).watchIcebreakers(currentUserAge: profile?.age ?? 18);
});
