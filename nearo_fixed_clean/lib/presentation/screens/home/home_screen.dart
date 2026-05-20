import 'package:flutter/material.dart';

import '../../../core/theme/nearo_theme.dart';
import '../matches/matches_screen.dart';
import '../nearby/nearby_screen.dart';
import '../profile/profile_screen.dart';
import '../venues/venues_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _index = 0;

  final _screens = const [
    NearbyScreen(),
    VenuesScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: NearoTheme.surface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Nearby'),
            BottomNavigationBarItem(icon: Icon(Icons.location_city), label: 'Venues'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
