import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/nearo_user.dart';

class NearbyScreen extends ConsumerWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(nearbyUsersProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby'),
        actions: [
          IconButton(
            tooltip: 'Refresh Wi‑Fi proximity',
            onPressed: currentUser == null ? null : () => _refreshProximity(ref, currentUser.uid),
            icon: const Icon(Icons.wifi_tethering),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(nearbyUsersProvider),
        child: nearby.when(
          data: (users) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!firebaseReady) const _DemoBanner(),
              const SizedBox(height: 12),
              Text(
                '${users.length} people nearby',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (users.isEmpty) const _EmptyNearbyState(),
              for (final user in users) _NearbyUserCard(user: user),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _ErrorState(message: 'Could not load nearby users.'),
        ),
      ),
    );
  }

  Future<void> _refreshProximity(WidgetRef ref, String uid) async {
    final hash = await ref.read(proximityServiceProvider).getCurrentWifiHash();
    await ref.read(userRepositoryProvider).updateWifiHash(uid: uid, wifiHash: hash);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(nearbyUsersProvider);
  }
}

class _NearbyUserCard extends ConsumerStatefulWidget {
  final NearoUser user;

  const _NearbyUserCard({required this.user});

  @override
  ConsumerState<_NearbyUserCard> createState() => _NearbyUserCardState();
}

class _NearbyUserCardState extends ConsumerState<_NearbyUserCard> {
  var _sent = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: NearoTheme.gold.withValues(alpha: 0.18),
              child: Text(widget.user.displayName.isEmpty ? '?' : widget.user.displayName[0].toUpperCase()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.user.displayName}, ${widget.user.age}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.user.moodStatus, style: const TextStyle(color: NearoTheme.gold)),
                  const SizedBox(height: 6),
                  Text(widget.user.bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _sent || currentUser == null
                  ? null
                  : () async {
                      await ref.read(signalRepositoryProvider).sendSignal(
                            senderId: currentUser.uid,
                            receiverId: widget.user.uid,
                            venueWifiHash: widget.user.wifiHash,
                            message: 'Hi from Nearo!',
                          );
                      if (mounted) setState(() => _sent = true);
                    },
              icon: Icon(_sent ? Icons.check : Icons.favorite_border),
              label: Text(_sent ? 'Sent' : 'Signal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: NearoTheme.neon.withValues(alpha: 0.14),
        border: Border.all(color: NearoTheme.neon.withValues(alpha: 0.2)),
      ),
      child: const Text('Demo mode: Firebase is not connected, so nearby people are sample data.'),
    );
  }
}

class _EmptyNearbyState extends StatelessWidget {
  const _EmptyNearbyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(child: Text('No visible users found at your current venue.')),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
