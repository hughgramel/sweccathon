import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../style/palette.dart';

class MapView extends StatelessWidget {
  final String? saveData;
  
  const MapView({super.key, this.saveData});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    
    // Parse the save data
    String saveId = '';
    String saveName = '';
    String saveProgress = '';
    
    if (saveData != null && saveData!.isNotEmpty) {
      final parts = Uri.decodeComponent(saveData!).split('|');
      if (parts.length >= 3) {
        saveId = parts[0];
        saveName = parts[1];
        saveProgress = parts[2];
      }
    }
    
    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      appBar: AppBar(
        title: const Text('Game Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'World Map',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (saveData != null && saveData!.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loaded Save Game',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(),
                      Text('Save ID: $saveId'),
                      const SizedBox(height: 8),
                      Text('Save Name: $saveName', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('Progress: $saveProgress'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Text('No save game data loaded'),
            ],
            const SizedBox(height: 20),
            const Text('Map View - Not Fully Implemented Yet'),
          ],
        ),
      ),
    );
  }
} 