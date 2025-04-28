enum ResourceType {
  gold,
  coal,
  iron,
  food,
  none
}

class QueuedBuild {
  final String buildingType;
  final String provinceId;
  final int timeStart;
  final int timeFinish;

  QueuedBuild({
    required this.buildingType,
    required this.provinceId,
    required this.timeStart,
    required this.timeFinish,
  });
}

class Building {
  final String id;
  final String name;
  final int industryBonus;
  final int goldBonus;
  final ResourceType? requiredResource;

  Building({
    required this.id,
    required this.name,
    required this.industryBonus,
    required this.goldBonus,
    this.requiredResource,
  });
}

class Province {
  final String id;
  final String name;
  final String path;
  final int population;
  final int goldIncome;
  final int industry;
  final List<Building> buildings;
  final ResourceType resourceType;
  final int army;
  final String owner;  // Nation tag of the owner

  Province({
    required this.id,
    required this.name,
    required this.path,
    required this.population,
    required this.goldIncome,
    required this.industry,
    required this.buildings,
    required this.resourceType,
    required this.army,
    required this.owner,
  });
}

class Nation {
  final String nationTag;
  final String name;
  final String color;
  final String hexColor;
  final List<String> nationProvinces;  // List of province IDs owned by this nation
  final int gold;
  final int researchPoints;
  final String? currentResearchId;
  final int currentResearchProgress;
  final List<QueuedBuild>? buildQueue;
  final bool isAI;

  Nation({
    required this.nationTag,
    required this.name,
    required this.color,
    required this.hexColor,
    required this.nationProvinces,
    required this.gold,
    required this.researchPoints,
    this.currentResearchId,
    required this.currentResearchProgress,
    this.buildQueue,
    required this.isAI,
  });

  // Calculate total resources - now takes provinces as parameter
  int getTotalPopulation(List<Province> allProvinces) => 
    nationProvinces.fold(0, (sum, id) => 
      sum + (allProvinces.firstWhere((p) => p.id == id).population));
  
  int getTotalGoldIncome(List<Province> allProvinces) => 
    nationProvinces.fold(0, (sum, id) => 
      sum + (allProvinces.firstWhere((p) => p.id == id).goldIncome));
  
  int getTotalIndustry(List<Province> allProvinces) => 
    nationProvinces.fold(0, (sum, id) => 
      sum + (allProvinces.firstWhere((p) => p.id == id).industry));
  
  int getTotalArmy(List<Province> allProvinces) => 
    nationProvinces.fold(0, (sum, id) => 
      sum + (allProvinces.firstWhere((p) => p.id == id).army));
  
  Map<ResourceType, int> getResourceCounts(List<Province> allProvinces) {
    final counts = <ResourceType, int>{};
    for (final provinceId in nationProvinces) {
      final province = allProvinces.firstWhere((p) => p.id == provinceId);
      counts[province.resourceType] = (counts[province.resourceType] ?? 0) + 1;
    }
    return counts;
  }
}

class Game {
  final String id;
  final String gameName;
  final int date;
  final String mapName;
  final String playerNationTag;
  final List<Nation> nations;
  final List<Province> provinces;  // All provinces in the game

  Game({
    required this.id,
    required this.gameName,
    required this.date,
    required this.mapName,
    required this.playerNationTag,
    required this.nations,
    required this.provinces,
  });

  Nation get playerNation => nations.firstWhere((n) => n.nationTag == playerNationTag);

  // Format the date as YYYY-MM-DD
  String get formattedDate {
    final startDate = DateTime(1836, 1, 1);
    final currentDate = startDate.add(Duration(days: date));
    return '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
  }

  /// Creates a new Game instance with modified gold for a nation
  Game modifyNationGold(String nationTag, int goldChange) {
    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations.map((nation) {
        if (nation.nationTag == nationTag) {
          return Nation(
            nationTag: nation.nationTag,
            name: nation.name,
            color: nation.color,
            hexColor: nation.hexColor,
            nationProvinces: nation.nationProvinces,
            gold: nation.gold + goldChange,
            researchPoints: nation.researchPoints,
            currentResearchId: nation.currentResearchId,
            currentResearchProgress: nation.currentResearchProgress,
            buildQueue: nation.buildQueue,
            isAI: nation.isAI,
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
    );
  }

  // Create a new game with an incremented date
  Game incrementDate() {
    Game game = Game(
      id: id,
      gameName: gameName,
      date: date + 1,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations,
      provinces: provinces,
    );
    // Find player nation and add 100 gold
    game = game.modifyNationGold(playerNationTag, 100);
    return game;
  }
} 