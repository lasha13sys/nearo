import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final locale = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('profile.title')),
        actions: [
          IconButton(
            tooltip: l10n.t('profile.signOut'),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profile.when(
        data: (item) {
          if (item == null || user == null) {
            return Center(child: Text(l10n.t('profile.noProfile')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: NearoTheme.gold.withValues(
                              alpha: 0.18,
                            ),
                            backgroundImage: item.photoUrl.isEmpty
                                ? null
                                : NetworkImage(item.photoUrl),
                            child: item.photoUrl.isEmpty
                                ? Text(
                                    item.nickname.isEmpty
                                        ? '?'
                                        : item.nickname
                                              .substring(0, 1)
                                              .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nickname,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  user.phoneNumber,
                                  style: const TextStyle(
                                    color: NearoTheme.mutedText,
                                  ),
                                ),
                                if (item.mood != null)
                                  Text(
                                    item.mood!,
                                    style: const TextStyle(
                                      color: NearoTheme.gold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        value: item.visible,
                        onChanged: (value) async {
                          await ref
                              .read(userRepositoryProvider)
                              .updateVisibility(uid: item.uid, visible: value);
                          ref.invalidate(currentUserProfileProvider);
                        },
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('visibility.visibleToNearby')),
                        subtitle: Text(l10n.t('visibility.subtitle')),
                      ),
                      const Divider(),
                      _Metric(
                        label: l10n.t('profile.signalsSent'),
                        value: item.signalsSent.toString(),
                      ),
                      _Metric(
                        label: l10n.t('profile.matches'),
                        value: item.matchesCount.toString(),
                      ),
                      _Metric(
                        label: l10n.t('profile.demoMode'),
                        value: firebaseReady
                            ? l10n.t('profile.no')
                            : l10n.t('profile.yes'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('language.title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<Locale>(
                        segments: [
                          ButtonSegment<Locale>(
                            value: const Locale('en'),
                            label: Text(l10n.t('language.english')),
                          ),
                          ButtonSegment<Locale>(
                            value: const Locale('ka'),
                            label: Text(l10n.t('language.georgian')),
                          ),
                        ],
                        selected: {locale},
                        onSelectionChanged: (selection) {
                          ref
                              .read(appLocaleProvider.notifier)
                              .setLocale(selection.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('profile.safety'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.t('profile.safetyText')),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.shield_outlined),
                        label: Text(l10n.t('profile.safetyTools')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.t('profile.loadError'))),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: NearoTheme.mutedText),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
