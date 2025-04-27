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
  });
}

class Nation {
  final String nationTag;
  final String name;
  final String color;
  final String hexColor;
  final List<Province> provinces;
  final List<Province>? borderProvinces;
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
    required this.provinces,
    this.borderProvinces,
    required this.gold,
    required this.researchPoints,
    this.currentResearchId,
    required this.currentResearchProgress,
    this.buildQueue,
    required this.isAI,
  });

  // Calculate total resources
  int get totalPopulation => provinces.fold(0, (sum, p) => sum + p.population);
  int get totalGoldIncome => provinces.fold(0, (sum, p) => sum + p.goldIncome);
  int get totalIndustry => provinces.fold(0, (sum, p) => sum + p.industry);
  int get totalArmy => provinces.fold(0, (sum, p) => sum + p.army);
  
  Map<ResourceType, int> get resourceCounts {
    final counts = <ResourceType, int>{};
    for (final province in provinces) {
      counts[province.resourceType] = (counts[province.resourceType] ?? 0) + 1;
    }
    return counts;
  }
}

class Game {
  final String id;
  final String gameName;
  final String date;
  final String mapName;
  final String playerNationTag;
  final List<Nation> nations;

  Game({
    required this.id,
    required this.gameName,
    required this.date,
    required this.mapName,
    required this.playerNationTag,
    required this.nations,
  });

  Nation get playerNation => nations.firstWhere((n) => n.nationTag == playerNationTag);

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
            provinces: nation.provinces,
            borderProvinces: nation.borderProvinces,
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
    );
  }
} 