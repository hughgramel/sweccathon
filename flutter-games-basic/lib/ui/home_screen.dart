import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../style/palette.dart';
import '../style/game_button.dart';
import '../models/save_game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Check if there's a recent game to determine whether to enable the Resume button
  // This is a simplified check - a real app would check actual save data
  bool hasRecentGame() {
    final saveGames = SaveGame.getDemoSaves();
    return saveGames.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final hasRecent = hasRecentGame();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                'Age of Focus',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151E2F),
                  fontFamily: 'MPLUS Rounded 1c',
                ),
              ),
              const SizedBox(height: 80),
              
              // Resume button
              GameButton(
                text: hasRecent ? 'Resume Nation' : 'No Recent Nation',
                emoji: '🏰',
                disabled: !hasRecent,
                onPressed: () {
                  if (hasRecent) {
                    // Get the most recent save and navigate to it
                    final saveGames = SaveGame.getDemoSaves();
                    final mostRecent = saveGames.reduce((a, b) => 
                      a.savedAt.isAfter(b.savedAt) ? a : b);
                    final encodedData = Uri.encodeComponent(
                      '${mostRecent.id}|${mostRecent.name}|${mostRecent.progressInfo}'
                    );
                    context.go('/map-view?saveData=$encodedData');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No recent games found')),
                    );
                  }
                },
              ),
              
              // New Nation button
              GameButton(
                text: 'New Nation',
                emoji: '⚔️',
                onPressed: () => context.go('/scenarios'),
              ),
              
              // Settings button in same style but with a different color
              GameButton(
                text: 'Settings',
                emoji: '⚙️',
                backgroundColor: const Color(0xFF50C878), // Emerald green
                shadowColor: const Color(0xFF2E8B57), // Sea green for shadow
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 