import 'package:clashofnations/widgets/interactive_map.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game_types.dart';
import '../data/world_1914.dart';
// import '../widgets/interactive_map.dart';
import '../widgets/resource_bar.dart';
import '../services/game_persistence_service.dart';
import '../widgets/popup.dart';
import 'dart:async';

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
  Province? selectedProvince;
  Timer? _tickTimer;
  bool _isPaused = true;
  int _currentSpeed = 1;  // Track current speed

  String _formatNumber(num number, {bool forGain = false}) {
    if (number == 0) return "0";
    
    bool isNegative = number < 0;
    number = number.abs();
    
    final suffixes = ["", "k", "m", "b", "t"];
    
    int suffixIndex = 0;
    while (number >= 1000 && suffixIndex < suffixes.length - 1) {
      number /= 1000;
      suffixIndex++;
    }
    
    String formatted;
    if (forGain) {
      // For gains, always show 3 significant digits
      if (number >= 100) {
        formatted = number.round().toString();
      } else if (number >= 10) {
        formatted = number.toStringAsFixed(1);
      } else {
        formatted = number.toStringAsFixed(2);
      }
      // Remove trailing zeros after decimal point
      if (formatted.contains('.')) {
        while (formatted.endsWith('0')) {
          formatted = formatted.substring(0, formatted.length - 1);
        }
        if (formatted.endsWith('.')) {
          formatted = formatted.substring(0, formatted.length - 1);
        }
      }
    } else {
      // Original formatting for non-gain numbers
      if (number >= 100) {
        formatted = number.round().toString();
      } else if (number >= 10) {
        formatted = number.toStringAsFixed(1);
        if (formatted.endsWith('.0')) {
          formatted = formatted.substring(0, formatted.length - 2);
        }
      } else {
        formatted = number.toStringAsFixed(2);
        if (formatted.endsWith('0')) {
          formatted = formatted.substring(0, formatted.length - 1);
          if (formatted.endsWith('.0')) {
            formatted = formatted.substring(0, formatted.length - 2);
          }
        }
      }
    }
    
    return (isNegative ? "-" : "") + formatted + suffixes[suffixIndex];
  }

  String _formatDate(int days) {
    final startDate = DateTime(1914, 1, 1);
    final date = startDate.add(Duration(days: days));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
    _tickTimer?.cancel();
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
          return;
        }
      }
      setState(() {
        currentGame = widget.game;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
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
    final nation = world1914.nations.firstWhere((n) => n.nationTag == widget.nationTag);
    setState(() {
      currentGame = Game(
        id: 'game_${DateTime.now().millisecondsSinceEpoch}',
        gameName: 'New Game',
        date: 0,  // Start at day 0 (1914-01-01)
        mapName: 'world_provinces',
        playerNationTag: widget.nationTag,
        nations: [nation, ...world1914.nations.where((n) => n.nationTag != widget.nationTag)],
        provinces: world1914.provinces,
      );
    });
  }

  void _showActionPopup(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Popup(
          title: action,
          width: 600,
          height: 700,
          onClose: () => Navigator.of(context).pop(),
          content: Center(
            child: Text(
              '$action Content Coming Soon',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }

  void _setGameSpeed(int speed) {
    _tickTimer?.cancel();
    setState(() {
      _currentSpeed = speed;
    });
    if (_isPaused) return;

    final intervals = {
      1: const Duration(seconds: 1),
      2: const Duration(milliseconds: 500),
      3: const Duration(milliseconds: 250),
      4: const Duration(milliseconds: 100),  // 10 ticks per second
    };

    _tickTimer = Timer.periodic(intervals[speed]!, (_) {
      setState(() {
        currentGame = currentGame.incrementDate();
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _tickTimer?.cancel();
      } else {
        _setGameSpeed(_currentSpeed); // Resume at current speed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // Bottom layer: Background
            Container(
              color: const Color.fromRGBO(143, 178, 187, 1.0),
            ),

            // Second layer: Interactive map
            Center(
              child: Container(
                color: const Color.fromRGBO(143, 178, 187, 1.0),
                child: InteractiveMap(
                  game: currentGame,
                  onGameUpdate: _handleGameUpdate,
                ),
              ),
            ),
            
            // Top layers: UI elements
            Column(
              children: [
                // Top bar with resource bar and date
                SafeArea(
                  child: Container(
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ResourceBar(
                                      nation: currentGame.playerNation,
                                      provinces: currentGame.provinces,
                                      game: currentGame,
                                    ),
                                    // Menu button
                                    Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () => _showMenuModal(context),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.menu,
                                              color: Colors.black87,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
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
                                    _formatDate(currentGame.date),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _SpeedButton(
                                    label: '1',
                                    isActive: !_isPaused && _currentSpeed == 1,
                                    isSelected: _currentSpeed == 1,
                                    onPressed: () {
                                      setState(() {
                                        _isPaused = false;
                                        _setGameSpeed(1);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 13),
                                  _SpeedButton(
                                    label: '2',
                                    isActive: !_isPaused && _currentSpeed == 2,
                                    isSelected: _currentSpeed == 2,
                                    onPressed: () {
                                      setState(() {
                                        _isPaused = false;
                                        _setGameSpeed(2);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 13),
                                  _SpeedButton(
                                    label: '3',
                                    isActive: !_isPaused && _currentSpeed == 3,
                                    isSelected: _currentSpeed == 3,
                                    onPressed: () {
                                      setState(() {
                                        _isPaused = false;
                                        _setGameSpeed(3);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 13),
                                  _SpeedButton(
                                    label: '4',
                                    isActive: !_isPaused && _currentSpeed == 4,
                                    isSelected: _currentSpeed == 4,
                                    onPressed: () {
                                      setState(() {
                                        _isPaused = false;
                                        _setGameSpeed(4);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 13),
                                  Container(
                                    transform: Matrix4.translationValues(0, -2, 0),
                                    width: 31,
                                    height: 31,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF67B9E7),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xFF4792BA),
                                          offset: Offset(0, 4),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: _togglePause,
                                        child: Center(
                                          child: Text(
                                            _isPaused ? '▶' : '⏸',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _ResourceItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String? gain;

  const _ResourceItem({
    required this.emoji,
    required this.value,
    this.gain,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
        if (gain != null) ...[
          const SizedBox(width: 4),
          Text(
            '+$gain',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SpeedButton({
    required this.label,
    required this.isActive,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0, -2, 0),
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: isSelected 
          ? const Color(0xFF67B9E7)  // Selected color
          : const Color(0xFF9DCFEF),  // Unselected color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isSelected
              ? const Color(0xFF4792BA)  // Selected shadow
              : const Color(0xFF7BAAC7),  // Unselected shadow
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 