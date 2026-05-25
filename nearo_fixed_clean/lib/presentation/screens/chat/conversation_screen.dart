import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/icebreaker.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String title;
  final String? matchId;
  final String? connectionId;
  final bool easyStart;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.title,
    this.matchId,
    this.connectionId,
    this.easyStart = false,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _controller = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref
        .watch(chatRepositoryProvider)
        .watchMessages(widget.conversationId);
    final conversation = ref.watch(conversationProvider(widget.conversationId));
    final icebreakers = ref.watch(icebreakersProvider);
    final connection = widget.connectionId == null
        ? null
        : ref.watch(connectionProvider(widget.connectionId!));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.3,
            colors: [Color(0x332E145A), NearoTheme.charcoal],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Nearo',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: NearoTheme.neon,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          conversation.when(
                            data: (item) => Text(
                              item?.venueName == null
                                  ? widget.title
                                  : 'Matched at ${item!.venueName}',
                              style: const TextStyle(
                                color: NearoTheme.mutedText,
                              ),
                            ),
                            loading: () => Text(
                              widget.title,
                              style: const TextStyle(
                                color: NearoTheme.mutedText,
                              ),
                            ),
                            error: (_, __) => Text(
                              widget.title,
                              style: const TextStyle(
                                color: NearoTheme.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),
              ),
              if (connection != null)
                connection.when(
                  data: (item) => item?.temporaryTimerEndsAt == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Temporary connection ends at ${TimeOfDay.fromDateTime(item!.temporaryTimerEndsAt!).format(context)}',
                            style: const TextStyle(color: NearoTheme.gold),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: messages,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? <ChatMessage>[];
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final message = items[index];
                        final isMine = message.senderId == widget.currentUserId;
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMine
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF8A35E8),
                                        Color(0xFF40205F),
                                      ],
                                    )
                                  : null,
                              color: isMine
                                  ? null
                                  : NearoTheme.elevated.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(message.text),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              icebreakers.when(
                data: (items) => _IcebreakerStrip(
                  items: items,
                  easyStart: widget.easyStart,
                  onTap: (text) => _sendText(text),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            senderId: widget.currentUserId,
            text: text,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _IcebreakerStrip extends StatelessWidget {
  final List<Icebreaker> items;
  final bool easyStart;
  final ValueChanged<String> onTap;

  const _IcebreakerStrip({
    required this.items,
    required this.easyStart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = easyStart
        ? items
        : items
              .where((item) => item.category != IcebreakerCategory.easyStart)
              .toList();
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: visibleItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = visibleItems[index];
          return ActionChip(
            label: Text(item.text),
            avatar: Icon(_iconFor(item.category), size: 18),
            onPressed: () => onTap(item.text),
            backgroundColor: NearoTheme.surface.withValues(alpha: 0.88),
            side: BorderSide(color: NearoTheme.neon.withValues(alpha: 0.24)),
          );
        },
      ),
    );
  }

  IconData _iconFor(IcebreakerCategory category) {
    return switch (category) {
      IcebreakerCategory.coffee => Icons.coffee,
      IcebreakerCategory.fun => Icons.sentiment_satisfied_alt,
      IcebreakerCategory.easyStart => Icons.auto_awesome,
      IcebreakerCategory.venue => Icons.location_city,
      IcebreakerCategory.custom => Icons.chat_bubble_outline,
    };
  }
}
