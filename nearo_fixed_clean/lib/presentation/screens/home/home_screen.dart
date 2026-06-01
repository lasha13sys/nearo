import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../matches/matches_screen.dart';
import '../nearby/nearby_screen.dart';
import '../profile/profile_screen.dart';
import '../venues/venues_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _index = 0;

  final _screens = const [
    _HomeLandingScreen(),
    NearbyScreen(),
    VenuesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: NearoTheme.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: l10n.t('nav.home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.radar),
              label: l10n.t('nav.nearby'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.location_on_outlined),
              label: l10n.t('nav.spots'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: l10n.t('nav.profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLandingScreen extends ConsumerWidget {
  const _HomeLandingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(nearbyUsersProvider).valueOrNull ?? const [];
    final matches = ref.watch(matchesProvider).valueOrNull ?? const [];
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.15,
            colors: [Color(0x332D2466), NearoTheme.charcoal],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            children: [
              Row(
                children: [
                  Text(
                    l10n.t('app.name'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: NearoTheme.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: NearoTheme.surface.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: NearoTheme.neon.withValues(alpha: 0.18),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: profile?.visible == true
                              ? NearoTheme.neon
                              : NearoTheme.mutedText,
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile?.visible == true
                              ? l10n.t('status.openToConnect')
                              : l10n.t('status.invisible'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: NearoTheme.surface.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: NearoTheme.neon.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('visibility.visibleNearby'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Switch(
                      value: profile?.visible ?? false,
                      onChanged: profile == null
                          ? null
                          : (value) async {
                              await ref
                                  .read(userRepositoryProvider)
                                  .updateVisibility(
                                    uid: profile.uid,
                                    visible: value,
                                  );
                              ref.invalidate(currentUserProfileProvider);
                              ref.invalidate(nearbyUsersProvider);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Center(
                child: Text(
                  l10n.peopleNearby(nearby.length),
                  style: const TextStyle(
                    color: NearoTheme.mutedText,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (nearby.isNotEmpty)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const CircleAvatar(
                      child: Icon(Icons.auto_awesome),
                    ),
                    title: Text(nearby.first.nickname),
                    subtitle: Text(nearby.first.moodStatus),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NearbyScreen(),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: const CircleAvatar(child: Icon(Icons.favorite)),
                  title: Text(
                    "${matches.length} ${l10n.t('home.activeMatches')}",
                  ),
                  subtitle: Text(l10n.t('home.matchSubtitle')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MatchesScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
