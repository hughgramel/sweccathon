/// A model representing a saved game state
class SaveGame {
  /// Unique identifier for the save game
  final int id;
  
  /// Name of the save file (user-defined or auto-generated)
  final String name;
  
  /// When the game was saved
  final DateTime savedAt;
  
  /// Total play time in minutes
  final int playTimeMinutes;
  
  /// Level or progress information
  final String progressInfo;
  
  SaveGame({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.playTimeMinutes,
    required this.progressInfo,
  });
  
  /// Creates demo save games for display
  static List<SaveGame> getDemoSaves() {
    return [
      SaveGame(
        id: 1,
        name: 'Main Adventure',
        savedAt: DateTime.now().subtract(const Duration(days: 1)),
        playTimeMinutes: 120,
        progressInfo: 'Level 5 - Forest of Shadows',
      ),
      SaveGame(
        id: 2,
        name: 'Side Quest',
        savedAt: DateTime.now().subtract(const Duration(hours: 5)),
        playTimeMinutes: 45,
        progressInfo: 'Level 2 - Mountain Pass',
      ),
      SaveGame(
        id: 3,
        name: 'New Game',
        savedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        playTimeMinutes: 10,
        progressInfo: 'Level 1 - Tutorial',
      ),
      SaveGame(
        id: 4,
        name: 'Hardcore Mode',
        savedAt: DateTime.now().subtract(const Duration(days: 3)),
        playTimeMinutes: 200,
        progressInfo: 'Level 8 - Dragon\'s Lair',
      ),
      SaveGame(
        id: 5,
        name: 'Speedrun Attempt',
        savedAt: DateTime.now().subtract(const Duration(hours: 12)),
        playTimeMinutes: 22,
        progressInfo: 'Level 3 - Castle Gate',
      ),
    ];
  }
  
  /// Format the saved date as a string
  String get formattedSavedDate {
    return '${savedAt.year}-${savedAt.month.toString().padLeft(2, '0')}-${savedAt.day.toString().padLeft(2, '0')} ${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')}';
  }
  
  /// Format play time as hours and minutes
  String get formattedPlayTime {
    final hours = playTimeMinutes ~/ 60;
    final minutes = playTimeMinutes % 60;
    
    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }
} 