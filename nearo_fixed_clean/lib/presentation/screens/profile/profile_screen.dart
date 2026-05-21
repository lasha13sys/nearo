import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profile.when(
        data: (item) {
          if (item == null || user == null) return const Center(child: Text('No profile loaded.'));
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
                            backgroundColor: NearoTheme.gold.withValues(alpha: 0.18),
                            backgroundImage: item.photoUrl.isEmpty ? null : NetworkImage(item.photoUrl),
                            child: item.photoUrl.isEmpty
                                ? Text(
                                    item.nickname.isEmpty ? '?' : item.nickname.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
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
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(user.phoneNumber, style: const TextStyle(color: NearoTheme.mutedText)),
                                if (item.mood != null)
                                  Text(item.mood!, style: const TextStyle(color: NearoTheme.gold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        value: item.visible,
                        onChanged: (value) async {
                          await ref.read(userRepositoryProvider).updateVisibility(uid: item.uid, visible: value);
                          ref.invalidate(currentUserProfileProvider);
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visible to nearby people'),
                        subtitle: const Text('Turn this off when you do not want to appear in Nearby.'),
                      ),
                      const Divider(),
                      _Metric(label: 'Signals sent', value: item.signalsSent.toString()),
                      _Metric(label: 'Matches', value: item.matchesCount.toString()),
                      _Metric(label: 'Demo mode', value: firebaseReady ? 'No' : 'Yes'),
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
                      const Text('Safety', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Meet in public places, respect boundaries, and use reporting tools if someone behaves inappropriately.'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.shield_outlined),
                        label: const Text('Report and block tools are available from match actions'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load profile.')),
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
          Expanded(child: Text(label, style: const TextStyle(color: NearoTheme.mutedText))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
