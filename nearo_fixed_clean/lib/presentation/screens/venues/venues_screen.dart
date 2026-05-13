import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/venue.dart';

class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(activeVenuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Venues')),
      body: venues.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _VenueCard(venue: items[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load venues.')),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Venue venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    venue.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                _EnergyBadge(value: venue.liveStats.socialEnergy),
              ],
            ),
            const SizedBox(height: 8),
            Text(venue.description, style: const TextStyle(color: NearoTheme.mutedText)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18, color: NearoTheme.gold),
                const SizedBox(width: 8),
                Expanded(child: Text(venue.address)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: venue.atmosphere.name),
                _Chip(label: venue.musicType),
                _Chip(label: '${venue.liveStats.activeUsers} active'),
                _Chip(label: '${venue.rating.toStringAsFixed(1)} ★'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: venue.liveStats.capacityPercent / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text('Capacity: ${venue.liveStats.capacityPercent}% • ${venue.hours}'),
          ],
        ),
      ),
    );
  }
}

class _EnergyBadge extends StatelessWidget {
  final int value;

  const _EnergyBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NearoTheme.gold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$value energy'),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: NearoTheme.elevated,
      side: BorderSide(color: Colors.white.withOpacity(0.06)),
    );
  }
}
