import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_types.dart';
import '../data/world_1836.dart';

/// Service responsible for saving and loading game state
class GamePersistenceService {
  static const String _currentGameKey = 'current_game';
  static const String _savedGamesKey = 'saved_games';
  static const int maxSaveSlots = 5;
  
  /// Singleton instance
  static final GamePersistenceService _instance = GamePersistenceService._internal();
  factory GamePersistenceService() => _instance;
  GamePersistenceService._internal();

  Nation getNationFromTagAndGame(String tag, Game game) {
    return game.nations.firstWhere((nation) => nation.nationTag == tag);
  }

  /// Saves the current game state
  /// 
  /// This will save both to the current game slot and to the list of saved games
  Future<void> saveGame(Game game) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert game to JSON
    final gameJson = _gameToJson(game);
    
    // Save as current game
    await prefs.setString(_currentGameKey, jsonEncode(gameJson));
    
    // Add to saved games list
    final savedGames = await _getSavedGames();
    savedGames[game.id] = gameJson;
    await prefs.setString(_savedGamesKey, jsonEncode(savedGames));
  }

  /// Loads the current game state
  /// 
  /// Returns the default 1836 scenario if no saved game exists
  Future<Game> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    final gameJson = prefs.getString(_currentGameKey);
    
    if (gameJson != null) {
      try {
        final decodedJson = jsonDecode(gameJson) as Map<String, dynamic>;
        return _gameFromJson(decodedJson);
      } catch (e) {
        print('Error loading saved game: $e');
        return world1836; // Fallback to default scenario
      }
    }
    
    return world1836; // Return default scenario if no save exists
  }

  /// Lists all saved games
  Future<Map<String, Game>> listSavedGames() async {
    final savedGamesJson = await _getSavedGames();
    
    return savedGamesJson.map((key, value) => 
      MapEntry(key, _gameFromJson(value as Map<String, dynamic>)));
  }

  /// Deletes a saved game
  Future<void> deleteSavedGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedGames = await _getSavedGames();
    
    savedGames.remove(gameId);
    await prefs.setString(_savedGamesKey, jsonEncode(savedGames));
  }

  /// Helper method to get saved games map
  Future<Map<String, dynamic>> _getSavedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGamesJson = prefs.getString(_savedGamesKey);
    
    if (savedGamesJson != null) {
      return Map<String, dynamic>.from(jsonDecode(savedGamesJson) as Map);
    }
    
    return {};
  }

  /// Converts a Game object to JSON
  Map<String, dynamic> _gameToJson(Game game) {
    return {
      'id': game.id,
      'gameName': game.gameName,
      'date': game.date,
      'mapName': game.mapName,
      'playerNationTag': game.playerNationTag,
      'nations': game.nations.map((nation) => _nationToJson(nation)).toList(),
    };
  }

  /// Converts a Nation object to JSON
  Map<String, dynamic> _nationToJson(Nation nation) {
    return {
      'nationTag': nation.nationTag,
      'name': nation.name,
      'color': nation.color,
      'hexColor': nation.hexColor,
      'provinces': nation.provinces.map((province) => _provinceToJson(province)).toList(),
      'gold': nation.gold,
      'researchPoints': nation.researchPoints,
      'currentResearchId': nation.currentResearchId,
      'currentResearchProgress': nation.currentResearchProgress,
      'buildQueue': nation.buildQueue?.map((build) => _queuedBuildToJson(build)).toList(),
      'isAI': nation.isAI,
    };
  }

  /// Converts a Province object to JSON
  Map<String, dynamic> _provinceToJson(Province province) {
    return {
      'id': province.id,
      'name': province.name,
      'path': province.path,
      'population': province.population,
      'goldIncome': province.goldIncome,
      'industry': province.industry,
      'buildings': province.buildings.map((building) => _buildingToJson(building)).toList(),
      'resourceType': province.resourceType.index,
      'army': province.army,
    };
  }

  /// Converts a Building object to JSON
  Map<String, dynamic> _buildingToJson(Building building) {
    return {
      'id': building.id,
      'name': building.name,
      'industryBonus': building.industryBonus,
      'goldBonus': building.goldBonus,
      'requiredResource': building.requiredResource?.index,
    };
  }

  /// Converts a QueuedBuild object to JSON
  Map<String, dynamic> _queuedBuildToJson(QueuedBuild build) {
    return {
      'buildingType': build.buildingType,
      'provinceId': build.provinceId,
      'timeStart': build.timeStart,
      'timeFinish': build.timeFinish,
    };
  }

  /// Creates a Game object from JSON
  Game _gameFromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      gameName: json['gameName'] as String,
      date: json['date'] as String,
      mapName: json['mapName'] as String,
      playerNationTag: json['playerNationTag'] as String,
      nations: (json['nations'] as List)
          .map((nationJson) => _nationFromJson(nationJson as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Creates a Nation object from JSON
  Nation _nationFromJson(Map<String, dynamic> json) {
    return Nation(
      nationTag: json['nationTag'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      hexColor: json['hexColor'] as String,
      provinces: (json['provinces'] as List)
          .map((provinceJson) => _provinceFromJson(provinceJson as Map<String, dynamic>))
          .toList(),
      gold: (json['gold'] as num).toInt(),
      researchPoints: (json['researchPoints'] as num).toInt(),
      currentResearchId: json['currentResearchId'] as String?,
      currentResearchProgress: (json['currentResearchProgress'] as num?)?.toInt() ?? 0,
      buildQueue: json['buildQueue'] != null
          ? (json['buildQueue'] as List)
              .map((buildJson) => _queuedBuildFromJson(buildJson as Map<String, dynamic>))
              .toList()
          : null,
      isAI: json['isAI'] as bool,
    );
  }

  /// Creates a Province object from JSON
  Province _provinceFromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      population: (json['population'] as num).toInt(),
      goldIncome: (json['goldIncome'] as num).toInt(),
      industry: (json['industry'] as num).toInt(),
      buildings: (json['buildings'] as List)
          .map((buildingJson) => _buildingFromJson(buildingJson as Map<String, dynamic>))
          .toList(),
      resourceType: ResourceType.values[json['resourceType'] as int],
      army: (json['army'] as num).toInt(),
    );
  }

  /// Creates a Building object from JSON
  Building _buildingFromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as String,
      name: json['name'] as String,
      industryBonus: (json['industryBonus'] as num).toInt(),
      goldBonus: (json['goldBonus'] as num).toInt(),
      requiredResource: json['requiredResource'] != null
          ? ResourceType.values[json['requiredResource'] as int]
          : null,
    );
  }

  /// Creates a QueuedBuild object from JSON
  QueuedBuild _queuedBuildFromJson(Map<String, dynamic> json) {
    return QueuedBuild(
      buildingType: json['buildingType'] as String,
      provinceId: json['provinceId'] as String,
      timeStart: (json['timeStart'] as num).toInt(),
      timeFinish: (json['timeFinish'] as num).toInt(),
    );
  }

  /// Saves the game to a specific slot
  Future<void> saveGameToSlot(Game game, int slotNumber) async {
    if (slotNumber < 0 || slotNumber >= maxSaveSlots) {
      throw Exception('Invalid save slot number');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final gameJson = _gameToJson(game);
    
    // Save to specific slot
    await prefs.setString('save_slot_$slotNumber', jsonEncode(gameJson));
  }

  /// Loads a game from a specific slot
  Future<Game?> loadGameFromSlot(int slotNumber) async {
    if (slotNumber < 0 || slotNumber >= maxSaveSlots) {
      throw Exception('Invalid save slot number');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final gameJson = prefs.getString('save_slot_$slotNumber');
    
    if (gameJson != null) {
      try {
        final decodedJson = jsonDecode(gameJson) as Map<String, dynamic>;
        return _gameFromJson(decodedJson);
      } catch (e) {
        print('Error loading saved game from slot $slotNumber: $e');
        return null;
      }
    }
    return null;
  }

  /// Gets all save slots with their games
  Future<List<Game?>> getAllSaveSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Game?> slots = [];
    
    for (int i = 0; i < maxSaveSlots; i++) {
      final gameJson = prefs.getString('save_slot_$i');
      if (gameJson != null) {
        try {
          final decodedJson = jsonDecode(gameJson) as Map<String, dynamic>;
          slots.add(_gameFromJson(decodedJson));
        } catch (e) {
          print('Error loading saved game from slot $i: $e');
          slots.add(null);
        }
      } else {
        slots.add(null);
      }
    }
    
    return slots;
  }

  /// Clears a specific save slot
  Future<void> clearSaveSlot(int slotNumber) async {
    if (slotNumber < 0 || slotNumber >= maxSaveSlots) {
      throw Exception('Invalid save slot number');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('save_slot_$slotNumber');
  }
} 