import 'dart:math';

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
  final List<String> atWarWith;
  final double armyReserve;  // New field for army reserves

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
    this.atWarWith = const [],
    required this.armyReserve,  // Add to constructor
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
    List<String>? atWarWith,
    double? armyReserve,  // Add to copyWith
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
      atWarWith: atWarWith ?? this.atWarWith,
      armyReserve: armyReserve ?? this.armyReserve,  // Add to copyWith
    );
  }

  // Calculate total resources - now takes provinces as parameter
  int getTotalPopulation(List<Province> allProvinces) {
    print('Calculating total population for ${nationTag}');
    print('Nation provinces: ${nationProvinces.join(", ")}');
    print('All provinces count: ${allProvinces.length}');
    final total = nationProvinces.fold(0, (sum, id) {
      final province = allProvinces.where((p) => p.id == id).firstOrNull;
      if (province == null) {
        print('Warning: Province $id not found for nation $nationTag');
      }
      return sum + (province?.population ?? 0);
    });
    print('Total population for $nationTag: $total');
    return total;
  }
  
  int getTotalGoldIncome(List<Province> allProvinces) {
    print('Calculating total gold income for ${nationTag}');
    return nationProvinces.fold(0, (sum, id) {
      final province = allProvinces.where((p) => p.id == id).firstOrNull;
      if (province == null) {
        print('Warning: Province $id not found for nation $nationTag');
      }
      return sum + (province?.goldIncome ?? 0);
    });
  }
  
  int getTotalIndustry(List<Province> allProvinces) => 
    nationProvinces.fold(0, (sum, id) => 
      sum + (allProvinces.where((p) => p.id == id).firstOrNull?.industry ?? 0));
  
  int getTotalArmy(List<Province> allProvinces) => 
    nationProvinces.fold(0, (sum, id) => 
      sum + (allProvinces.where((p) => p.id == id).firstOrNull?.army ?? 0));
  
  Map<ResourceType, int> getResourceCounts(List<Province> allProvinces) {
    final counts = <ResourceType, int>{};
    for (final provinceId in nationProvinces) {
      final province = allProvinces.where((p) => p.id == provinceId).firstOrNull;
      if (province != null) {
        counts[province.resourceType] = (counts[province.resourceType] ?? 0) + 1;
      }
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
  final List<Province> provinces;
  final Map<String, ResourceGains> _cachedGains = {};
  final int _lastGainUpdateMonth;

  Game({
    required this.id,
    required this.gameName,
    required this.date,
    required this.mapName,
    required this.playerNationTag,
    required this.nations,
    required this.provinces,
  }) : _lastGainUpdateMonth = DateTime(1914, 1, 1).add(Duration(days: date)).month;

  Nation get playerNation => nations.firstWhere((n) => n.nationTag == playerNationTag);

  String get formattedDate {
    final startDate = DateTime(1914, 1, 1);
    final currentDate = startDate.add(Duration(days: date));
    return '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
  }

  int get currentMonth {
    final startDate = DateTime(1914, 1, 1);
    final currentDate = startDate.add(Duration(days: date));
    return currentDate.month;
  }

  ResourceGains getResourceGains(String nationTag) {
    // Return cached gains if we're in the same month
    if (_cachedGains.containsKey(nationTag) && 
        _cachedGains[nationTag]!.lastCalculatedMonth == currentMonth) {
      return _cachedGains[nationTag]!;
    }
    
    final nation = nations.firstWhere((n) => n.nationTag == nationTag);
    
    // Calculate monthly gains (only once per month)
    final totalIndustry = nation.getTotalIndustry(provinces);
    final totalPopulation = nation.getTotalPopulation(provinces);
    
    // Calculate monthly gains (30 days worth)
    final monthlyGoldGain = totalIndustry * 0.03 * 30;
    final monthlyPopulationGain = totalPopulation * 0.00003 * 30;
    final monthlyArmyGain = totalPopulation * 0.00010 * 30;
    
    final gains = ResourceGains(
      goldGain: monthlyGoldGain,
      populationGain: monthlyPopulationGain,
      armyGain: monthlyArmyGain,
      lastCalculatedMonth: currentMonth,
    );
    
    _cachedGains[nationTag] = gains;
    return gains;
  }

  Game incrementDate() {
    final newDate = date + 1;
    final newMonth = DateTime(1914, 1, 1).add(Duration(days: newDate)).month;
    final isNewMonth = newMonth != currentMonth;
    
    // Process movements and get updated nations/provinces
    final gameAfterMovements = _processMovements();
    
    // Only update resources on the first of each month
    final updatedNations = gameAfterMovements.nations.map((nation) {
      if (isNewMonth) {
        final gains = getResourceGains(nation.nationTag);
        return nation.copyWith(
          gold: nation.gold + gains.goldGain,
          armyReserve: nation.armyReserve + gains.armyGain,
        );
      }
      return nation;
    }).toList();

    final updatedProvinces = gameAfterMovements.provinces.map((province) {
      if (isNewMonth) {
        final ownerNation = nations.firstWhere((n) => n.nationTag == province.owner);
        final gains = getResourceGains(province.owner);
        
        // Add all population gain to a random province
        if (ownerNation.nationProvinces.contains(province.id)) {
          final random = Random();
          final isSelected = random.nextDouble() < 1.0 / ownerNation.nationProvinces.length;
          if (isSelected) {
            return province.copyWith(
              population: province.population + gains.populationGain.round(),
            );
          }
        }
      }
      return province;
    }).toList();

    return Game(
      id: id,
      gameName: gameName,
      date: newDate,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: updatedNations,
      provinces: updatedProvinces,
    );
  }

  Game _processMovements() {
    final updatedNations = nations.map((nation) {
      final updatedMovements = <Movement>[];
      var provincesToUpdate = <String, int>{};

      // Process each movement
      for (final movement in nation.movements) {
        if (movement.daysLeft > 1) {
          // Movement continues
          updatedMovements.add(movement.copyWith(daysLeft: movement.daysLeft - 1));
        } else {
          // Movement completes - add army to destination province
          provincesToUpdate[movement.destinationProvinceId] = 
            (provincesToUpdate[movement.destinationProvinceId] ?? 0) + movement.armySize;
          // Remove army from origin province
          provincesToUpdate[movement.originProvinceId] = 
            (provincesToUpdate[movement.originProvinceId] ?? 0) - movement.armySize;
        }
      }

      // Update nation with new movements
      return nation.copyWith(movements: updatedMovements);
    }).toList();

    // Update provinces with completed movements
    final updatedProvinces = provinces.map((province) {
      final totalArmyChange = updatedNations.fold<int>(0, (sum, nation) {
        final completedMovements = nation.movements.where(
          (m) => m.daysLeft <= 1 && 
          (m.destinationProvinceId == province.id || m.originProvinceId == province.id)
        ).toList();

        return sum + completedMovements.fold<int>(0, (moveSum, movement) {
          if (movement.destinationProvinceId == province.id) {
            return moveSum + movement.armySize;
          } else if (movement.originProvinceId == province.id) {
            return moveSum - movement.armySize;
          }
          return moveSum;
        });
      });

      if (totalArmyChange != 0) {
        return province.copyWith(army: province.army + totalArmyChange);
      }
      return province;
    }).toList();

    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: updatedNations,
      provinces: updatedProvinces,
    );
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
            atWarWith: nation.atWarWith,
            armyReserve: nation.armyReserve,
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
    );
  }

  /// Declare war between two nations
  Game declareWar(String attackerTag, String defenderTag) {
    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations.map((nation) {
        if (nation.nationTag == attackerTag) {
          return nation.copyWith(
            atWarWith: [...nation.atWarWith, defenderTag],
          );
        } else if (nation.nationTag == defenderTag) {
          return nation.copyWith(
            atWarWith: [...nation.atWarWith, attackerTag],
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
    );
  }

  /// Make peace between two nations
  Game makePeace(String nation1Tag, String nation2Tag) {
    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations.map((nation) {
        if (nation.nationTag == nation1Tag) {
          return nation.copyWith(
            atWarWith: nation.atWarWith.where((tag) => tag != nation2Tag).toList(),
          );
        } else if (nation.nationTag == nation2Tag) {
          return nation.copyWith(
            atWarWith: nation.atWarWith.where((tag) => tag != nation1Tag).toList(),
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
    );
  }

  /// Form an alliance between two nations
  Game formAlliance(String nation1Tag, String nation2Tag) {
    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations.map((nation) {
        if (nation.nationTag == nation1Tag) {
          return nation.copyWith(
            allies: [...nation.allies, nation2Tag],
          );
        } else if (nation.nationTag == nation2Tag) {
          return nation.copyWith(
            allies: [...nation.allies, nation1Tag],
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
    );
  }

  /// Break an alliance between two nations
  Game breakAlliance(String nation1Tag, String nation2Tag) {
    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations.map((nation) {
        if (nation.nationTag == nation1Tag) {
          return nation.copyWith(
            allies: nation.allies.where((tag) => tag != nation2Tag).toList(),
          );
        } else if (nation.nationTag == nation2Tag) {
          return nation.copyWith(
            allies: nation.allies.where((tag) => tag != nation1Tag).toList(),
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
    );
  }
}

class ResourceGains {
  final double goldGain;
  final double populationGain;
  final double armyGain;
  final int lastCalculatedMonth;  // Add to track when gains were last calculated

  const ResourceGains({
    required this.goldGain,
    required this.populationGain,
    required this.armyGain,
    required this.lastCalculatedMonth,  // Add to constructor
  });
} 