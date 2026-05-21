import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/venue.dart';
import '../../../domain/entities/venue_event.dart';

class VenuesScreen extends ConsumerStatefulWidget {
  const VenuesScreen({super.key});

  @override
  ConsumerState<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends ConsumerState<VenuesScreen> {
  Venue? _selected;

  @override
  Widget build(BuildContext context) {
    final venues = ref.watch(activeVenuesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0x33211944), NearoTheme.charcoal],
          ),
        ),
        child: SafeArea(
          child: venues.when(
            data: (items) {
              final selected = _selected ?? (items.isNotEmpty ? items.first : null);
              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 360),
                    children: [
                      Row(
                        children: [
                          Text(
                            'Nearo',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: NearoTheme.text,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.search)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _SpotFilters(),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 420,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF101827), Color(0xFF080A10)],
                                  ),
                                ),
                              ),
                            ),
                            for (var i = 0; i < items.length; i++)
                              Positioned(
                                left: 40.0 + (i * 86) % 260,
                                top: 70.0 + (i * 92) % 260,
                                child: _VenuePin(
                                  venue: items[i],
                                  selected: selected?.id == items[i].id,
                                  onTap: () => setState(() => _selected = items[i]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (selected != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _VenueBottomSheet(venue: selected),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Could not load spots.')),
          ),
        ),
      ),
    );
  }
}

class _SpotFilters extends StatelessWidget {
  const _SpotFilters();

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('Near Me', Icons.navigation),
      ('1km', Icons.circle_outlined),
      ('3km', Icons.circle_outlined),
      ('Trending', Icons.trending_up),
      ('Jazz', Icons.music_note),
      ('Chill', Icons.spa),
      ('Lively', Icons.graphic_eq),
      ('Romantic', Icons.favorite_border),
      ('Party', Icons.auto_awesome),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < filters.length; i++)
          Chip(
            avatar: Icon(filters[i].$2, size: 18),
            label: Text(filters[i].$1),
            backgroundColor: i == 0 ? NearoTheme.danger.withValues(alpha: 0.24) : NearoTheme.surface,
            side: BorderSide(color: NearoTheme.neon.withValues(alpha: i == 0 ? 0.4 : 0.15)),
          ),
      ],
    );
  }
}

class _VenuePin extends StatelessWidget {
  final Venue venue;
  final bool selected;
  final VoidCallback onTap;

  const _VenuePin({
    required this.venue,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: NearoTheme.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? NearoTheme.danger : NearoTheme.neon.withValues(alpha: 0.35)),
              boxShadow: [BoxShadow(color: NearoTheme.neon.withValues(alpha: 0.24), blurRadius: 18)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: selected ? NearoTheme.danger : NearoTheme.neon),
                const SizedBox(width: 6),
                Text('${venue.liveStats.openUsersCount}'),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down, color: selected ? NearoTheme.danger : NearoTheme.neon, size: 38),
        ],
      ),
    );
  }
}

class _VenueBottomSheet extends StatelessWidget {
  final Venue venue;

  const _VenueBottomSheet({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NearoTheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: venue.photoUrl == null
                      ? Container(color: NearoTheme.elevated)
                      : Image.network(venue.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: NearoTheme.elevated)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venue.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('${venue.vibe} • ${venue.musicType}', style: const TextStyle(color: NearoTheme.mutedText)),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Stat(icon: Icons.groups, value: '${venue.liveStats.openUsersCount}', label: 'Open Now')),
              Expanded(child: _Stat(icon: Icons.favorite, value: '${venue.liveStats.matchesTonight}', label: 'Matches Tonight')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('SOCIAL ENERGY', style: TextStyle(color: NearoTheme.mutedText, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(venue.liveStats.socialEnergy > 75 ? 'High' : 'Medium', style: const TextStyle(color: NearoTheme.danger)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: venue.liveStats.socialEnergy / 100, minHeight: 9, borderRadius: BorderRadius.circular(99)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => VenueDetailScreen(venue: venue)),
            ),
            child: const Text('View Spot'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: NearoTheme.neon),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: NearoTheme.mutedText)),
          ],
        ),
      ],
    );
  }
}

class VenueDetailScreen extends ConsumerWidget {
  final Venue venue;

  const VenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(venueEventsProvider(venue.id));
    return Scaffold(
      appBar: AppBar(title: Text(venue.name)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 220,
              child: venue.photoUrl == null
                  ? Container(color: NearoTheme.elevated)
                  : Image.network(venue.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: NearoTheme.elevated)),
            ),
          ),
          const SizedBox(height: 18),
          Text(venue.description, style: const TextStyle(color: NearoTheme.mutedText)),
          const SizedBox(height: 18),
          _Stat(icon: Icons.graphic_eq, value: '${venue.liveStats.socialEnergy}%', label: 'Social energy'),
          const SizedBox(height: 18),
          Text('Events tonight', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          events.when(
            data: (items) => Column(
              children: [
                for (final item in items) _EventTile(event: item),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load events.'),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final VenueEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Text('${event.vibe} • ${event.music} • ${event.waitTime}'),
        trailing: Text('${event.crowdLevel}%'),
      ),
    );
  }
}
