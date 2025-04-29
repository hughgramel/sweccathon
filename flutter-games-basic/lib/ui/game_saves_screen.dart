import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/save_game.dart';
import '../style/palette.dart';
import '../services/game_persistence_service.dart';
import '../models/game_types.dart';

class GameSavesScreen extends StatelessWidget {
  const GameSavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final gamePersistence = GamePersistenceService();
    
    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      appBar: AppBar(
        title: const Text('Load Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<List<Game?>>(
        future: gamePersistence.getAllSaveSlots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error loading saves: ${snapshot.error}'));
          }
          
          final saveGames = snapshot.data ?? [];
          
          return ListView.builder(
            itemCount: saveGames.length,
            itemBuilder: (context, index) {
              final game = saveGames[index];
              if (game == null) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.save),
                    ),
                    title: const Text('Empty Slot'),
                    subtitle: const Text('No saved game'),
                    isThreeLine: false,
                  ),
                );
              }
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.backgroundLevelSelection,
                      palette.backgroundLevelSelection.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Card(
                  color: Colors.transparent,
                  elevation: 0,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.save),
                    ),
                    title: Text(
                      game.gameName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${game.formattedDate}'),
                        Text('Nation: ${game.playerNation.name}'),
                        Text('Provinces: ${game.playerNation.nationProvinces.length}'),
                        Text('Armies: ${game.playerNation.getTotalArmy(game.provinces)}'),
                        if (game.playerNation.movements.isNotEmpty)
                          Text('Active Movements: ${game.playerNation.movements.length}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      context.go('/game-view', extra: {
                        'game': game,
                        'saveSlot': index,
                        'nationTag': game.playerNationTag,
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 