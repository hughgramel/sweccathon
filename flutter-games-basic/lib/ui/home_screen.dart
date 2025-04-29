import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../style/game_button.dart';
import '../models/game_types.dart';
import '../services/game_persistence_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GamePersistenceService _gamePersistence = GamePersistenceService();
  Game? _lastSavedGame;
  int? _lastSavedSlot;
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
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    
    _loadLastSavedGame();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSavedGame() async {
    setState(() => _isLoading = true);
    
    try {
      final slots = await _gamePersistence.getAllSaveSlots();
      Game? lastGame;
      int? lastSlot;
      
      // Find the most recently used slot
      for (int i = 0; i < slots.length; i++) {
        if (slots[i] != null) {
          lastGame = slots[i];
          lastSlot = i;
        }
      }
      
      setState(() {
        _lastSavedGame = lastGame;
        _lastSavedSlot = lastSlot;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading last saved game: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleResumeGame() {
    if (_lastSavedGame != null && _lastSavedSlot != null) {
      setState(() => _isTransitioning = true);
      _fadeController.forward().then((_) {
        if (mounted) {
          context.go('/game-view/${_lastSavedGame!.playerNationTag}', 
            extra: {'saveSlot': _lastSavedSlot});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
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
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      GameButton(
                        text: _lastSavedGame != null 
                            ? 'Resume Game (${_lastSavedGame!.playerNation.name})'
                            : 'No Saved Game',
                        emoji: '🏰',
                        disabled: _lastSavedGame == null || _isTransitioning,
                        onPressed: _handleResumeGame,
                      ),
                    GameButton(
                      onPressed: () => context.go('/save-games'),
                      text: 'Load Game',
                      emoji: '💾',
                      disabled: _isTransitioning,
                    ),
                    GameButton(
                      onPressed: () => context.go('/scenarios'),
                      text: 'New Game',
                      emoji: '🎮',
                      disabled: _isTransitioning,
                    ),
                    GameButton(
                      onPressed: () => context.go('/settings'),
                      text: 'Settings',
                      emoji: '⚙️',
                      disabled: _isTransitioning,
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
                  // Navigation handling
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 