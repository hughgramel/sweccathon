import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game_types.dart';
import '../services/game_persistence_service.dart';
import '../data/world_1836.dart';

class SaveGameScreen extends StatefulWidget {
  final Game? newGame;

  const SaveGameScreen({super.key, this.newGame});

  @override
  State<SaveGameScreen> createState() => _SaveGameScreenState();
}

class _SaveGameScreenState extends State<SaveGameScreen> {
  final GamePersistenceService _gamePersistence = GamePersistenceService();
  List<Game?> _saveSlots = List.filled(5, null);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaveSlots();
  }

  Future<void> _loadSaveSlots() async {
    setState(() => _isLoading = true);
    try {
      final slots = await _gamePersistence.getAllSaveSlots();
      setState(() {
        _saveSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading save slots: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSaveSlot(int index) {
    final game = _saveSlots[index];
    final bool isEmpty = game == null;
    final bool isNewGame = widget.newGame != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: isEmpty 
          ? const Icon(Icons.add_circle_outline, size: 40)
          : Image.asset(
              'assets/flags/${game.playerNationTag.toLowerCase()}.png',
              width: 40,
              height: 30,
              fit: BoxFit.contain,
            ),
        title: Text(isEmpty ? 'Empty Slot ${index + 1}' : game.playerNation.name),
        subtitle: isEmpty 
          ? const Text('No saved game')
          : Text('Last played: ${DateTime.now().toString().split('.')[0]}'),
        onTap: () async {
          if (isNewGame) {
            // Save new game to this slot
            await _gamePersistence.saveGameToSlot(widget.newGame!, index);
            if (mounted) {
              context.go('/game-view/${widget.newGame!.playerNationTag}', 
                extra: {'saveSlot': index});
            }
          } else if (!isEmpty) {
            // Load existing game
            context.go('/game-view/${game.playerNationTag}', 
              extra: {'saveSlot': index});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.newGame != null ? 'Select Save Slot' : 'Load Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => _buildSaveSlot(index),
          ),
    );
  }
} 