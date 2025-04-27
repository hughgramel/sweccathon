import 'package:basic/widgets/interactive_map.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game_types.dart';
import '../data/world_1836.dart';
// import '../widgets/interactive_map.dart';
import '../widgets/resource_bar.dart';
import '../services/game_persistence_service.dart';

class GameViewScreen extends StatefulWidget {
  final Game game;
  final int? saveSlot;
  final String nationTag;

  const GameViewScreen({
    super.key,
    required this.game,
    this.saveSlot,
    required this.nationTag,
  });

  @override
  State<GameViewScreen> createState() => _GameViewScreenState();
}

class _GameViewScreenState extends State<GameViewScreen> {
  late Game currentGame;
  final gamePersistence = GamePersistenceService();

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    if (widget.saveSlot != null) {
      final savedGame = await gamePersistence.loadGameFromSlot(widget.saveSlot!);
      if (savedGame != null) {
        setState(() {
          currentGame = savedGame;
        });
        return;
      }
    }
    setState(() {
      currentGame = widget.game;
    });
  }

  void _showMenuModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save Game'),
                onTap: () async {
                  Navigator.pop(context);
                  // If we don't have a save slot, go to save game screen
                  if (widget.saveSlot == null) {
                    context.go('/save-games', extra: {'newGame': currentGame});
                  } else {
                    // Save to current slot
                    await gamePersistence.saveGameToSlot(currentGame, widget.saveSlot!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Game saved to slot ${widget.saveSlot! + 1}')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Return Home'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addGold() {
    setState(() {
      currentGame = currentGame.modifyNationGold(currentGame.playerNationTag, 100);
    });
  }

  void _createNewGame() {
    final nation = world1836.nations.firstWhere((n) => n.nationTag == widget.nationTag);
    setState(() {
      currentGame = Game(
        id: 'game_${DateTime.now().millisecondsSinceEpoch}',
        gameName: 'New Game',
        date: '1836-01-01',
        mapName: 'world_provinces',
        playerNationTag: widget.nationTag,
        nations: [nation, ...world1836.nations.where((n) => n.nationTag != widget.nationTag)],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    print('GameViewScreen build');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom layer: Grid background
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),

          // Second layer: Interactive map
          InteractiveMap(game: currentGame),
          // Top layers: UI elements
          Column(
            children: [
              // Top bar with resource bar
              SafeArea(
                child: ResourceBar(
                  nation: currentGame.playerNation,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: FloatingActionButton(
              onPressed: () => _showMenuModal(context),
              child: const Icon(Icons.menu),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: FloatingActionButton(
              onPressed: _addGold,
              child: const Icon(Icons.monetization_on),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

// Grid painter for background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
} 