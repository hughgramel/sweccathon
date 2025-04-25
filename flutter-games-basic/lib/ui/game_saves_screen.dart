import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/save_game.dart';
import '../style/palette.dart';

class GameSavesScreen extends StatelessWidget {
  const GameSavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final saveGames = SaveGame.getDemoSaves();
    
    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      appBar: AppBar(
        title: const Text('Load Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView.builder(
        itemCount: saveGames.length,
        itemBuilder: (context, index) {
          final saveGame = saveGames[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.save),
              ),
              title: Text(
                saveGame.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saved: ${saveGame.formattedSavedDate}'),
                  Text('Playtime: ${saveGame.formattedPlayTime}'),
                  Text(saveGame.progressInfo),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                // Navigate to map view with save game data
                final encodedData = Uri.encodeComponent('${saveGame.id}|${saveGame.name}|${saveGame.progressInfo}');
                context.go('/map-view?saveData=$encodedData');
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creating new game save')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 