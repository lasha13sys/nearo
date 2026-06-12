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
      extendBody: true,
      body: _screens[_index],
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: NearoTheme.glass,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: NearoTheme.glassBorder),
            boxShadow: NearoTheme.glowShadow(NearoTheme.neon, opacity: 0.18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
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
        decoration: const BoxDecoration(gradient: NearoTheme.pageGradient),
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
              const SizedBox(height: 42),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: NearoTheme.glassDecoration(
                  radius: 28,
                  glowColor: NearoTheme.gold,
                  glowOpacity: 0.14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _LiveMetric(
                        icon: Icons.groups_2_outlined,
                        value: '${nearby.length}',
                        label: l10n.t('home.peopleOpen'),
                      ),
                    ),
                    Expanded(
                      child: _LiveMetric(
                        icon: Icons.favorite_border,
                        value: '${matches.length}',
                        label: l10n.t('home.matchesTonight'),
                      ),
                    ),
                    Expanded(
                      child: _LiveMetric(
                        icon: profile?.visible == true
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        value: profile?.visible == true
                            ? l10n.t('profile.yes')
                            : l10n.t('profile.no'),
                        label: l10n.t('home.visible'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: NearoTheme.glassDecoration(
                  radius: 32,
                  borderColor: NearoTheme.neon.withValues(alpha: 0.28),
                  glowColor: NearoTheme.neon,
                  glowOpacity: 0.18,
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
              Text(
                l10n.peopleNearby(nearby.length),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: NearoTheme.mutedText,
                  fontWeight: FontWeight.w700,
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

class _LiveMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _LiveMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: NearoTheme.gold),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: NearoTheme.mutedText, fontSize: 12),
        ),
      ],
    );
  }
}
