import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/contact_reveal.dart';
import '../../../domain/entities/interaction_option.dart';
import '../../../domain/entities/match.dart';
import '../chat/conversation_screen.dart';

class MatchInteractionScreen extends ConsumerWidget {
  final Match match;
  final String currentUserId;

  const MatchInteractionScreen({
    super.key,
    required this.match,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionId = match.connectionId ?? match.id;
    final connection = ref.watch(connectionProvider(connectionId));
    final reveals = ref.watch(contactRevealsProvider(match.id));
    final otherUserId = match.otherUserId(currentUserId);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0x44281054), NearoTheme.charcoal],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                "It's a Match",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: NearoTheme.text,
                    ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _GlowAvatar(label: 'You'),
                        const SizedBox(width: 52),
                        _GlowAvatar(label: otherUserId.isEmpty ? 'Match' : otherUserId.substring(0, 1).toUpperCase()),
                      ],
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NearoTheme.elevated,
                        boxShadow: [BoxShadow(color: NearoTheme.neon.withValues(alpha: 0.65), blurRadius: 28)],
                      ),
                      child: const Icon(Icons.favorite, color: NearoTheme.neon),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              connection.when(
                data: (item) => item?.temporaryTimerEndsAt == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Temporary connection until ${TimeOfDay.fromDateTime(item!.temporaryTimerEndsAt!).format(context)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: NearoTheme.mutedText),
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              reveals.when(
                data: (items) => _RevealPanel(
                  reveals: items,
                  currentUserId: currentUserId,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              for (final option in InteractionOption.defaults)
                _OptionTile(
                  option: option,
                  onTap: () => _handleOption(context, ref, option, otherUserId),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: otherUserId.isEmpty
                          ? null
                          : () async {
                              await ref.read(userRepositoryProvider).blockUser(
                                    currentUserId: currentUserId,
                                    blockedUserId: otherUserId,
                                  );
                              if (context.mounted) Navigator.of(context).pop();
                            },
                      icon: const Icon(Icons.block),
                      label: const Text('Block'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: otherUserId.isEmpty
                          ? null
                          : () async {
                              await ref.read(reportServiceProvider).reportUser(
                                    reporterId: currentUserId,
                                    reportedUserId: otherUserId,
                                    reason: 'safety_concern',
                                  );
                              if (context.mounted) _showSnack(context, 'Report submitted for moderation.');
                            },
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleOption(
    BuildContext context,
    WidgetRef ref,
    InteractionOption option,
    String otherUserId,
  ) async {
    final connectionId = match.connectionId ?? match.id;
    await ref.read(signalRepositoryProvider).selectInteractionOption(
          connectionId: connectionId,
          optionId: option.id,
        );

    switch (option.type) {
      case InteractionOptionType.openChat:
      case InteractionOptionType.easyStart:
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(
              conversationId: match.conversationId ?? match.id,
              currentUserId: currentUserId,
              title: option.type == InteractionOptionType.easyStart ? 'Easy Start' : 'Match chat',
              matchId: match.id,
              connectionId: connectionId,
              easyStart: option.type == InteractionOptionType.easyStart,
            ),
          ),
        );
      case InteractionOptionType.leaveNumber:
        await _requestReveal(ref, otherUserId, ContactRevealType.phone);
        if (context.mounted) _showSnack(context, 'Phone reveal requested. It unlocks only after approval.');
      case InteractionOptionType.leaveSocial:
        await _requestReveal(ref, otherUserId, ContactRevealType.instagram);
        if (context.mounted) _showSnack(context, 'Social reveal requested. It unlocks only after approval.');
      case InteractionOptionType.meetNow:
        if (context.mounted) _showSnack(context, 'Meet Now intent saved. No exact location is shared.');
      case InteractionOptionType.funGame:
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Fun Game'),
              content: const Text('Quick pick: Mountains or sea? Jazz or techno? This placeholder is connected to the match state.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ],
            ),
          );
        }
    }
  }

  Future<void> _requestReveal(WidgetRef ref, String otherUserId, ContactRevealType type) {
    return ref.read(contactRevealRepositoryProvider).requestReveal(
          matchId: match.id,
          requesterId: currentUserId,
          receiverId: otherUserId,
          contactType: type,
        );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RevealPanel extends ConsumerWidget {
  final List<ContactReveal> reveals;
  final String currentUserId;

  const _RevealPanel({
    required this.reveals,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reveals.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          for (final reveal in reveals)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NearoTheme.surface.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NearoTheme.gold.withValues(alpha: 0.2)),
              ),
              child: _RevealContent(reveal: reveal, currentUserId: currentUserId),
            ),
        ],
      ),
    );
  }
}

class _RevealContent extends ConsumerWidget {
  final ContactReveal reveal;
  final String currentUserId;

  const _RevealContent({
    required this.reveal,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReceiver = reveal.receiverId == currentUserId;
    if (reveal.canShowTo(currentUserId)) {
      return Text(
        '${reveal.contactType.name}: ${reveal.revealedValue}',
        style: const TextStyle(fontWeight: FontWeight.w800, color: NearoTheme.gold),
      );
    }
    if (reveal.status == ContactRevealStatus.requested && isReceiver) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Approve ${reveal.contactType.name} reveal?', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => ref.read(contactRevealRepositoryProvider).respond(
                      revealId: reveal.id,
                      status: ContactRevealStatus.declined,
                    ),
                child: const Text('Decline'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => ref.read(contactRevealRepositoryProvider).respond(
                      revealId: reveal.id,
                      status: ContactRevealStatus.approved,
                    ),
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      );
    }
    return Text(
      '${reveal.contactType.name} reveal: ${reveal.status.name}',
      style: const TextStyle(color: NearoTheme.mutedText),
    );
  }
}

class _GlowAvatar extends StatelessWidget {
  final String label;

  const _GlowAvatar({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: NearoTheme.neon, width: 2),
        boxShadow: [BoxShadow(color: NearoTheme.neon.withValues(alpha: 0.35), blurRadius: 24)],
      ),
      child: Center(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final InteractionOption option;
  final VoidCallback onTap;

  const _OptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: option.enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: NearoTheme.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: NearoTheme.neon.withValues(alpha: 0.35)),
            boxShadow: option.type == InteractionOptionType.meetNow
                ? [BoxShadow(color: NearoTheme.danger.withValues(alpha: 0.25), blurRadius: 24)]
                : null,
          ),
          child: Row(
            children: [
              Icon(_iconData(option.type), color: NearoTheme.neon, size: 30),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  option.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.chevron_right, color: NearoTheme.mutedText),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconData(InteractionOptionType type) {
    return switch (type) {
      InteractionOptionType.meetNow => Icons.local_fire_department,
      InteractionOptionType.easyStart => Icons.coffee,
      InteractionOptionType.funGame => Icons.casino,
      InteractionOptionType.leaveSocial => Icons.phone_iphone,
      InteractionOptionType.leaveNumber => Icons.call,
      InteractionOptionType.openChat => Icons.chat_bubble,
    };
  }
}
