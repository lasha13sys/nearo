import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';

class FunGameScreen extends ConsumerStatefulWidget {
  final String connectionId;

  const FunGameScreen({super.key, required this.connectionId});

  @override
  ConsumerState<FunGameScreen> createState() => _FunGameScreenState();
}

class _FunGameScreenState extends ConsumerState<FunGameScreen> {
  final Map<String, String> _answers = {};

  static const _questions = [
    ('q1', 'Mountains or sea?', ['Mountains', 'Sea']),
    ('q2', 'Jazz or techno?', ['Jazz', 'Techno']),
    ('q3', 'Quiet corner or dance floor?', ['Quiet corner', 'Dance floor']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fun Game')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Quick compatibility round',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick fast. Your choices are saved to the match interaction state.',
            style: TextStyle(color: NearoTheme.mutedText),
          ),
          const SizedBox(height: 24),
          for (final question in _questions)
            _QuestionCard(
              question: question,
              value: _answers[question.$1],
              onPick: _pickAnswer,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _answers.length == _questions.length
                ? () => Navigator.of(context).pop()
                : null,
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAnswer(String questionId, String answer) async {
    setState(() => _answers[questionId] = answer);
    await ref
        .read(signalRepositoryProvider)
        .selectInteractionOption(
          connectionId: widget.connectionId,
          optionId: 'fun_game:$questionId:$answer',
        );
  }
}

class _QuestionCard extends StatelessWidget {
  final (String, String, List<String>) question;
  final String? value;
  final void Function(String questionId, String answer) onPick;

  const _QuestionCard({
    required this.question,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NearoTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NearoTheme.neon.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.$2,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              for (final option in question.$3)
                ChoiceChip(
                  label: Text(option),
                  selected: value == option,
                  onSelected: (_) => onPick(question.$1, option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
