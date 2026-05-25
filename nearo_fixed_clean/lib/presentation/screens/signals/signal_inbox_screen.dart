import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/signal.dart';
import '../matches/match_interaction_screen.dart';

class SignalInboxScreen extends ConsumerWidget {
  const SignalInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signals = ref.watch(incomingSignalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Sparks')),
      body: signals.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No incoming Sparks right now.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => _SignalCard(signal: items[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load signals.')),
      ),
    );
  }
}

class _SignalCard extends ConsumerStatefulWidget {
  final Signal signal;

  const _SignalCard({required this.signal});

  @override
  ConsumerState<_SignalCard> createState() => _SignalCardState();
}

class _SignalCardState extends ConsumerState<_SignalCard> {
  var _loading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final sender = ref
        .watch(userProfileByIdProvider(widget.signal.senderId))
        .valueOrNull;
    final title = sender == null
        ? 'Someone nearby sent you a Spark'
        : '${sender.nickname} sent you a Spark';
    final subtitle = widget.signal.isExpired ? 'Expired' : 'Expires soon';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: NearoTheme.neon.withValues(alpha: 0.18),
                  backgroundImage: sender?.photoUrl.trim().isNotEmpty == true
                      ? NetworkImage(sender!.photoUrl)
                      : null,
                  child: sender?.photoUrl.trim().isNotEmpty == true
                      ? null
                      : const Icon(Icons.auto_awesome, color: NearoTheme.neon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: NearoTheme.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.signal.message?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(widget.signal.message!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading || widget.signal.isExpired
                        ? null
                        : () => _respond(
                            context,
                            SignalStatus.declined,
                            currentUser?.uid,
                          ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading || widget.signal.isExpired
                        ? null
                        : () => _respond(
                            context,
                            SignalStatus.accepted,
                            currentUser?.uid,
                          ),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    SignalStatus status,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(signalRepositoryProvider)
          .respondToSignal(signalId: widget.signal.id, status: status);
      if (status == SignalStatus.accepted) {
        final match = await ref
            .read(signalRepositoryProvider)
            .waitForMatchBetween(
              currentUserId: currentUserId,
              otherUserId: widget.signal.senderId,
            );
        if (!context.mounted) return;
        if (match != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => MatchInteractionScreen(
                match: match,
                currentUserId: currentUserId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Spark accepted. Match is being prepared.'),
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Spark declined.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
