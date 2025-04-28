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

class _GameViewScreenState extends State<GameViewScreen> with SingleTickerProviderStateMixin {
  late Game currentGame;
  final gamePersistence = GamePersistenceService();
  bool _isLoading = true;
  bool _isTransitioning = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    // Set loading state immediately
    setState(() {
      _isLoading = true;
    });
    
    // Start loading game
    _loadGame();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    try {
      if (widget.saveSlot != null) {
        final savedGame = await gamePersistence.loadGameFromSlot(widget.saveSlot!);
        if (savedGame != null) {
          setState(() {
            currentGame = savedGame;
            _isLoading = false;
          });
          _fadeController.forward();
          // Print game state
          print('\n=== Game State ===');
          print('Game ID: ${savedGame.id}');
          print('Game Name: ${savedGame.gameName}');
          print('Date: ${savedGame.date}');
          print('Map: ${savedGame.mapName}');
          print('Player Nation Tag: ${savedGame.playerNationTag}');
          print('\nNations:');
          for (final nation in savedGame.nations) {
            print('\n--- ${nation.name} (${nation.nationTag}) ---');
            print('Color: ${nation.color}');
            print('Gold: ${nation.gold}');
            print('Research Points: ${nation.researchPoints}');
            print('Current Research: ${nation.currentResearchId} (${nation.currentResearchProgress}%)');
            print('Is AI: ${nation.isAI}');
            print('Total Population: ${nation.getTotalPopulation(savedGame.provinces)}');
            print('Total Gold Income: ${nation.getTotalGoldIncome(savedGame.provinces)}');
            print('Total Industry: ${nation.getTotalIndustry(savedGame.provinces)}');
            print('Total Army: ${nation.getTotalArmy(savedGame.provinces)}');
            print('Resources: ${nation.getResourceCounts(savedGame.provinces)}');
            print('\nProvinces:');
            for (final provinceId in nation.nationProvinces) {
              final province = savedGame.provinces.firstWhere((p) => p.id == provinceId);
              print('  - ${province.name}');
              print('    Population: ${province.population}');
              print('    Gold Income: ${province.goldIncome}');
              print('    Industry: ${province.industry}');
              print('    Army: ${province.army}');
              print('    Resource: ${province.resourceType}');
            }
          }
          print('\n=================\n');
          return;
        }
      }
      setState(() {
        currentGame = widget.game;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      print('Error loading game: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading game. Please try again.')),
        );
      }
    }
  }

  void _handleReturnHome() {
    setState(() => _isTransitioning = true);
    _fadeController.forward().then((_) {
      if (mounted) {
        context.go('/');
      }
    });
  }

  void _showMenuModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,  // Use root navigator
      builder: (BuildContext modalContext) {  // Use separate context for modal
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save Game'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  if (widget.saveSlot == null) {
                    context.go('/save-games', extra: {'newGame': currentGame});
                  } else {
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
                  print('Return Home');
                  // Close modal using modal's context
                  Navigator.pop(modalContext);
                  // Navigate using GoRouter
                  GoRouter.of(context).goNamed('/');
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

  void _handleGameUpdate(Game updatedGame) {
    setState(() {
      currentGame = updatedGame;
    });
  }

  void _createNewGame() {
    final nation = world1836.nations.firstWhere((n) => n.nationTag == widget.nationTag);
    setState(() {
      currentGame = Game(
        id: 'game_${DateTime.now().millisecondsSinceEpoch}',
        gameName: 'New Game',
        date: 0,  // Start at day 0 (1836-01-01)
        mapName: 'world_provinces',
        playerNationTag: widget.nationTag,
        nations: [nation, ...world1836.nations.where((n) => n.nationTag != widget.nationTag)],
        provinces: world1836.provinces,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    print('GameViewScreen build');
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Game...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Bottom layer: Grid background
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(),
            ),

            // Second layer: Interactive map
            InteractiveMap(
              game: currentGame,
              onGameUpdate: _handleGameUpdate,
            ),
            // Top layers: UI elements
            Column(
              children: [
                // Top bar with resource bar
                SafeArea(
                  child: Column(
                    children: [
                      ResourceBar(
                        nation: currentGame.playerNation,
                        provinces: currentGame.provinces,
                      ),
                      // Date box
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/flags/${currentGame.playerNationTag.toLowerCase()}.png',
                                    width: 24,
                                    height: 18,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentGame.formattedDate,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    currentGame = currentGame.incrementDate();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Tick'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showMenuModal(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.menu,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _addGold,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.monetization_on,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
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