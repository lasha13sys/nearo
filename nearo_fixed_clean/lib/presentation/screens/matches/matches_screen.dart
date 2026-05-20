import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/match.dart';
import '../chat/conversation_screen.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: matches.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No matches yet. Send a signal to someone nearby.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => _MatchCard(
              match: items[index],
              currentUserId: currentUser?.uid ?? '',
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load matches.')),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final String currentUserId;

  const _MatchCard({required this.match, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final otherUserId = match.otherUserId(currentUserId);
    final conversationId = match.conversationId ?? match.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: NearoTheme.gold.withValues(alpha: 0.18),
          child: const Icon(Icons.favorite, color: NearoTheme.gold),
        ),
        title: Text('Match with $otherUserId'),
        subtitle: Text('Created ${match.createdAt.toLocal()}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(
              conversationId: conversationId,
              currentUserId: currentUserId,
              title: 'Match chat',
            ),
          ),
        ),
      ),
    );
  }
}
