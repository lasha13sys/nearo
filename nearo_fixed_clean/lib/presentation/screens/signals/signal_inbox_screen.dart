import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/signal.dart';

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

class _SignalCard extends ConsumerWidget {
  final Signal signal;

  const _SignalCard({required this.signal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: const Icon(Icons.auto_awesome, color: NearoTheme.neon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Someone nearby sent you a Spark',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (signal.message?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(signal.message!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(signalRepositoryProvider).respondToSignal(
                          signalId: signal.id,
                          status: SignalStatus.declined,
                        ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(signalRepositoryProvider).respondToSignal(
                            signalId: signal.id,
                            status: SignalStatus.accepted,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Spark accepted. Creating match...')),
                        );
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
