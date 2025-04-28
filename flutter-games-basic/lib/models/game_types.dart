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
  final int army;  // Standing army in this province
  final String owner;  // Nation tag that owns this province

  const Province({
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

  Province copyWith({
    String? id,
    String? name,
    String? path,
    int? population,
    int? goldIncome,
    int? industry,
    List<Building>? buildings,
    ResourceType? resourceType,
    int? army,
    String? owner,
  }) {
    return Province(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      population: population ?? this.population,
      goldIncome: goldIncome ?? this.goldIncome,
      industry: industry ?? this.industry,
      buildings: buildings ?? this.buildings,
      resourceType: resourceType ?? this.resourceType,
      army: army ?? this.army,
      owner: owner ?? this.owner,
    );
  }
}

class Movement {
  final String originProvinceId;
  final String destinationProvinceId;
  final int daysLeft;
  final int armySize;

  const Movement({
    required this.originProvinceId,
    required this.destinationProvinceId,
    required this.daysLeft,
    required this.armySize,
  });

  Movement copyWith({
    String? originProvinceId,
    String? destinationProvinceId,
    int? daysLeft,
    int? armySize,
  }) {
    return Movement(
      originProvinceId: originProvinceId ?? this.originProvinceId,
      destinationProvinceId: destinationProvinceId ?? this.destinationProvinceId,
      daysLeft: daysLeft ?? this.daysLeft,
      armySize: armySize ?? this.armySize,
    );
  }
}

class Nation {
  final String nationTag;
  final String name;
  final String color;
  final String hexColor;
  final List<String> nationProvinces;
  final List<String> allies;
  final List<String> borderProvinces;
  final double gold;
  final double researchPoints;
  final String? currentResearchId;
  final double currentResearchProgress;
  final List<QueuedBuild>? buildQueue;
  final bool isAI;
  final List<Movement> movements;

  Nation({
    required this.nationTag,
    required this.name,
    required this.color,
    required this.hexColor,
    required this.nationProvinces,
    this.allies = const [],
    this.borderProvinces = const [],
    required this.gold,
    required this.researchPoints,
    this.currentResearchId,
    required this.currentResearchProgress,
    this.buildQueue,
    required this.isAI,
    this.movements = const [],
  });

  Nation copyWith({
    String? nationTag,
    String? name,
    String? color,
    String? hexColor,
    List<String>? nationProvinces,
    List<String>? allies,
    List<String>? borderProvinces,
    double? gold,
    double? researchPoints,
    String? currentResearchId,
    double? currentResearchProgress,
    List<QueuedBuild>? buildQueue,
    bool? isAI,
    List<Movement>? movements,
  }) {
    return Nation(
      nationTag: nationTag ?? this.nationTag,
      name: name ?? this.name,
      color: color ?? this.color,
      hexColor: hexColor ?? this.hexColor,
      nationProvinces: nationProvinces ?? this.nationProvinces,
      allies: allies ?? this.allies,
      borderProvinces: borderProvinces ?? this.borderProvinces,
      gold: gold ?? this.gold,
      researchPoints: researchPoints ?? this.researchPoints,
      currentResearchId: currentResearchId ?? this.currentResearchId,
      currentResearchProgress: currentResearchProgress ?? this.currentResearchProgress,
      buildQueue: buildQueue ?? this.buildQueue,
      isAI: isAI ?? this.isAI,
      movements: movements ?? this.movements,
    );
  }

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
            allies: nation.allies,
            borderProvinces: nation.borderProvinces,
            gold: nation.gold + goldChange,
            researchPoints: nation.researchPoints,
            currentResearchId: nation.currentResearchId,
            currentResearchProgress: nation.currentResearchProgress,
            buildQueue: nation.buildQueue,
            isAI: nation.isAI,
            movements: nation.movements,
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
    );
  }

  // Create a new game with an incremented date
  Game incrementDate() {
    // Process movements
    final updatedNations = nations.map((nation) {
      final updatedMovements = <Movement>[];
      var provincesToUpdate = <String, int>{};

      // Process each movement
      for (final movement in nation.movements) {
        if (movement.daysLeft > 1) {
          // Movement continues
          updatedMovements.add(movement.copyWith(daysLeft: movement.daysLeft - 1));
        } else {
          // Movement completes
          provincesToUpdate[movement.destinationProvinceId] = 
            (provincesToUpdate[movement.destinationProvinceId] ?? 0) + movement.armySize;
        }
      }

      // Update nation with new movements
      return nation.copyWith(movements: updatedMovements);
    }).toList();

    // Update provinces with completed movements
    final updatedProvinces = provinces.map((province) {
      for (final nation in updatedNations) {
        final completedMovements = nation.movements
            .where((m) => m.daysLeft <= 1 && m.destinationProvinceId == province.id)
            .toList();
            
        if (completedMovements.isNotEmpty) {
          final totalIncomingArmy = completedMovements
              .fold(0, (sum, movement) => sum + movement.armySize);
              
          return province.copyWith(army: province.army + totalIncomingArmy);
        }
      }
      return province;
    }).toList();

    return Game(
      id: id,
      gameName: gameName,
      date: date + 1,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: updatedNations,
      provinces: updatedProvinces,
    );
  }
} 