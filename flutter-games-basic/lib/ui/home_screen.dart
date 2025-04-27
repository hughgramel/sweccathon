import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../style/game_button.dart';
import '../models/game_types.dart';
import '../data/world_1836.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Check if there's a recent game to determine whether to enable the Resume button
  bool hasRecentGame() {
    return world1836.playerNation != null;
  }

  @override
  Widget build(BuildContext context) {
    final hasRecent = hasRecentGame();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Age of Focus',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameButton(
                    text: hasRecent ? 'Resume Game (${world1836.playerNation.name})' : 'No Recent Nation',
                    emoji: '🏰',
                    disabled: !hasRecent,
                    onPressed: () {
                      if (hasRecent) {
                        print('Resuming game for ${world1836.playerNationTag}');
                        context.go('/game-view/${world1836.playerNationTag}');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No recent games found')),
                        );
                      }
                    },
                  ),
                  GameButton(
                    text: 'New Game',
                    emoji: '⚔️',
                    onPressed: () => context.go('/scenarios'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Statistics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
              currentIndex: 0,
              selectedItemColor: const Color(0xFF5DADE2),
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Already on home
                    break;
                  case 1:
                    // Navigate to statistics
                    break;
                  case 2:
                    // Navigate to profile
                    // context.go('/settings');
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 