import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/nearo_user.dart';
import '../signals/signal_inbox_screen.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  var _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final nearby = ref.watch(nearbyUsersProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.25,
            colors: [Color(0x44311754), NearoTheme.charcoal],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(nearbyUsersProvider),
            child: nearby.when(
              data: (users) {
                final filteredUsers = _applyFilter(users);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.t('app.name'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: NearoTheme.neon,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: l10n.t('nearby.incomingSparks'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SignalInboxScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_none),
                        ),
                        IconButton(
                          tooltip: l10n.t('nearby.refreshWifi'),
                          onPressed: currentUser == null
                              ? null
                              : () => _refreshProximity(ref, currentUser.uid),
                          icon: const Icon(Icons.wifi_tethering),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.t('nearby.title'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile?.visible == true
                          ? l10n.t('nearby.visibleSubtitle')
                          : l10n.t('nearby.invisibleSubtitle'),
                      style: const TextStyle(color: NearoTheme.mutedText),
                    ),
                    const SizedBox(height: 20),
                    _VisibilityPanel(
                      visible: profile?.visible ?? false,
                      userId: currentUser?.uid,
                    ),
                    const SizedBox(height: 18),
                    _FilterChips(
                      selected: _selectedFilter,
                      onSelected: (value) =>
                          setState(() => _selectedFilter = value),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.peopleNearby(filteredUsers.length),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filteredUsers.isEmpty) const _EmptyNearbyState(),
                    for (final user in filteredUsers)
                      _NearbyUserCard(user: user),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _ErrorState(message: l10n.t('nearby.error')),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshProximity(WidgetRef ref, String uid) async {
    final hash = await ref.read(proximityServiceProvider).getCurrentWifiHash();
    await ref
        .read(userRepositoryProvider)
        .updateWifiHash(uid: uid, wifiHash: hash);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(nearbyUsersProvider);
  }

  List<NearoUser> _applyFilter(List<NearoUser> users) {
    return switch (_selectedFilter) {
      'openToMeet' =>
        users
            .where((user) => user.moodStatus.toLowerCase().contains('meet'))
            .toList(),
      'easyStart' =>
        users
            .where((user) => user.moodStatus.toLowerCase().contains('easy'))
            .toList(),
      'partyMood' =>
        users
            .where((user) => user.moodStatus.toLowerCase().contains('party'))
            .toList(),
      'chill' =>
        users
            .where((user) => user.moodStatus.toLowerCase().contains('chill'))
            .toList(),
      _ => users,
    };
  }
}

class _VisibilityPanel extends ConsumerWidget {
  final bool visible;
  final String? userId;

  const _VisibilityPanel({required this.visible, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NearoTheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: NearoTheme.neon.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.t('visibility.visibleNearby'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Switch(
            value: visible,
            onChanged: userId == null
                ? null
                : (value) async {
                    await ref
                        .read(userRepositoryProvider)
                        .updateVisibility(uid: userId!, visible: value);
                    ref.invalidate(currentUserProfileProvider);
                    ref.invalidate(nearbyUsersProvider);
                  },
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = [
      ('all', l10n.t('filter.all'), Icons.auto_awesome),
      ('openToMeet', l10n.t('filter.openToMeet'), Icons.favorite_border),
      (
        'easyStart',
        l10n.t('filter.easyStart'),
        Icons.tips_and_updates_outlined,
      ),
      ('partyMood', l10n.t('filter.partyMood'), Icons.music_note),
      ('chill', l10n.t('filter.chill'), Icons.spa_outlined),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.$1 == selected;
          return ChoiceChip(
            avatar: Icon(filter.$3, size: 18),
            label: Text(filter.$2),
            selected: isSelected,
            onSelected: (_) => onSelected(filter.$1),
            backgroundColor: isSelected
                ? NearoTheme.neon.withValues(alpha: 0.45)
                : NearoTheme.surface,
            side: BorderSide(
              color: NearoTheme.neon.withValues(
                alpha: isSelected ? 0.55 : 0.18,
              ),
            ),
          );
        },
      ),
    );
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
  var _loading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NearoTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: NearoTheme.neon.withValues(alpha: 0.12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 124,
              height: 132,
              child: widget.user.photoUrl.isEmpty
                  ? Container(
                      color: NearoTheme.elevated,
                      child: Center(
                        child: Text(_initial(widget.user.nickname)),
                      ),
                    )
                  : Image.network(
                      widget.user.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: NearoTheme.elevated,
                        child: Center(
                          child: Text(_initial(widget.user.nickname)),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.nickname,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _MoodBadge(label: widget.user.moodStatus),
                const SizedBox(height: 14),
                Text(
                  widget.user.bio ?? l10n.t('nearby.bioFallback'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: NearoTheme.mutedText),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _sent || _loading || currentUser == null
                        ? null
                        : () => _sendSignal(currentUser.uid),
                    icon: Icon(_sent ? Icons.check : Icons.auto_awesome),
                    label: Text(
                      _sent
                          ? l10n.t('nearby.sent')
                          : l10n.t('nearby.sendSpark'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSignal(String currentUserId) async {
    setState(() => _loading = true);
    final result = await ref
        .read(signalRepositoryProvider)
        .sendSignal(
          senderId: currentUserId,
          receiverId: widget.user.uid,
          venueWifiHash: widget.user.wifiHash,
          message: 'Hi from Nearo!',
        );
    if (mounted) {
      setState(() {
        _sent = result.success;
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  String _initial(String value) {
    return value.trim().isEmpty
        ? '?'
        : value.trim().substring(0, 1).toUpperCase();
  }
}

class _MoodBadge extends StatelessWidget {
  final String label;

  const _MoodBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NearoTheme.neon.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NearoTheme.neon.withValues(alpha: 0.24)),
      ),
      child: Text(label, style: const TextStyle(color: NearoTheme.text)),
    );
  }
}

class _EmptyNearbyState extends StatelessWidget {
  const _EmptyNearbyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(child: Text(l10n.t('nearby.empty'))),
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
