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
  final int army;
  final String owner;
  final List<String> borderingProvinces;

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
    this.borderingProvinces = const [],
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
    List<String>? borderingProvinces,
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
      borderingProvinces: borderingProvinces ?? this.borderingProvinces,
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
  final double armyReserve;

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
    required this.armyReserve,
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
    double? armyReserve,
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
      armyReserve: armyReserve ?? this.armyReserve,
    );
  }

  int getTotalPopulation(List<Province> allProvinces) {
    final total = nationProvinces.fold(0, (sum, id) {
      final province = allProvinces.where((p) => p.id == id).firstOrNull;
      if (province == null) {
        print('Warning: Province $id not found for nation $nationTag');
      }
      return sum + (province?.population ?? 0);
    });
    return total;
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

class Battle {
  final String provinceId;
  final String attackerTag;
  final String defenderTag;
  final int attackerArmy;
  final int defenderArmy;
  final int attackerCasualties;
  final int defenderCasualties;
  final bool isActive;

  const Battle({
    required this.provinceId,
    required this.attackerTag,
    required this.defenderTag,
    required this.attackerArmy,
    required this.defenderArmy,
    this.attackerCasualties = 0,
    this.defenderCasualties = 0,
    this.isActive = true,
  });

  Battle copyWith({
    String? provinceId,
    String? attackerTag,
    String? defenderTag,
    int? attackerArmy,
    int? defenderArmy,
    int? attackerCasualties,
    int? defenderCasualties,
    bool? isActive,
  }) {
    return Battle(
      provinceId: provinceId ?? this.provinceId,
      attackerTag: attackerTag ?? this.attackerTag,
      defenderTag: defenderTag ?? this.defenderTag,
      attackerArmy: attackerArmy ?? this.attackerArmy,
      defenderArmy: defenderArmy ?? this.defenderArmy,
      attackerCasualties: attackerCasualties ?? this.attackerCasualties,
      defenderCasualties: defenderCasualties ?? this.defenderCasualties,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ResourceGains {
  final double goldGain;
  final double populationGain;
  final double armyGain;
  final int lastCalculatedMonth;

  const ResourceGains({
    required this.goldGain,
    required this.populationGain,
    required this.armyGain,
    required this.lastCalculatedMonth,
  });
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
  final List<Battle> battles;

  Game({
    required this.id,
    required this.gameName,
    required this.date,
    required this.mapName,
    required this.playerNationTag,
    required this.nations,
    required this.provinces,
    this.battles = const [],
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
    if (_cachedGains.containsKey(nationTag) && 
        _cachedGains[nationTag]!.lastCalculatedMonth == currentMonth) {
      return _cachedGains[nationTag]!;
    }
    
    final nation = nations.firstWhere((n) => n.nationTag == nationTag);
    
    final totalIndustry = nation.getTotalIndustry(provinces);
    final totalPopulation = nation.getTotalPopulation(provinces);
    
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
    
    // Process battles
    final gameAfterBattles = _processBattles(gameAfterMovements);
    
    // Only update resources on the first of each month
    final updatedNations = gameAfterBattles.nations.map((nation) {
      if (isNewMonth) {
        final gains = getResourceGains(nation.nationTag);
        return nation.copyWith(
          gold: nation.gold + gains.goldGain,
          armyReserve: nation.armyReserve + gains.armyGain,
        );
      }
      return nation;
    }).toList();

    final updatedProvinces = gameAfterBattles.provinces.map((province) {
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
      battles: gameAfterBattles.battles,
    );
  }

  Game _processMovements() {
    final updatedNations = nations.map((nation) {
      final updatedMovements = <Movement>[];
      var provincesToUpdate = <String, int>{};

      for (final movement in nation.movements) {
        if (movement.daysLeft > 1) {
          updatedMovements.add(movement.copyWith(daysLeft: movement.daysLeft - 1));
        } else {
          provincesToUpdate[movement.destinationProvinceId] = 
            (provincesToUpdate[movement.destinationProvinceId] ?? 0) + movement.armySize;
          provincesToUpdate[movement.originProvinceId] = 
            (provincesToUpdate[movement.originProvinceId] ?? 0) - movement.armySize;
        }
      }

      return nation.copyWith(movements: updatedMovements);
    }).toList();

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
      battles: battles,
    );
  }

  Game _processBattles(Game game) {
    final updatedBattles = <Battle>[];
    final updatedProvinces = List<Province>.from(game.provinces);
    final updatedNations = List<Nation>.from(game.nations);

    for (final battle in game.battles) {
      if (!battle.isActive) {
        updatedBattles.add(battle);
        continue;
      }

      // Simulate battle tick
      final newAttackerArmy = max(0, battle.attackerArmy - 1000);
      final newDefenderArmy = max(0, battle.defenderArmy - 1000);
      
      final newAttackerCasualties = battle.attackerCasualties + (battle.attackerArmy - newAttackerArmy);
      final newDefenderCasualties = battle.defenderCasualties + (battle.defenderArmy - newDefenderArmy);

      final isBattleOver = newAttackerArmy == 0 || newDefenderArmy == 0;
      
      final updatedBattle = battle.copyWith(
        attackerArmy: newAttackerArmy,
        defenderArmy: newDefenderArmy,
        attackerCasualties: newAttackerCasualties,
        defenderCasualties: newDefenderCasualties,
        isActive: !isBattleOver,
      );

      updatedBattles.add(updatedBattle);

      if (isBattleOver) {
        // Update province owner if defender lost
        if (newDefenderArmy == 0) {
          final provinceIndex = updatedProvinces.indexWhere((p) => p.id == battle.provinceId);
          if (provinceIndex != -1) {
            updatedProvinces[provinceIndex] = updatedProvinces[provinceIndex].copyWith(
              owner: battle.attackerTag,
              army: newAttackerArmy,
            );
          }
        }
      }
    }

    return Game(
      id: game.id,
      gameName: game.gameName,
      date: game.date,
      mapName: game.mapName,
      playerNationTag: game.playerNationTag,
      nations: updatedNations,
      provinces: updatedProvinces,
      battles: updatedBattles,
    );
  }

  Game startBattle(String provinceId, String attackerTag, String defenderTag, int attackerArmy, int defenderArmy) {
    final newBattle = Battle(
      provinceId: provinceId,
      attackerTag: attackerTag,
      defenderTag: defenderTag,
      attackerArmy: attackerArmy,
      defenderArmy: defenderArmy,
    );

    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations,
      provinces: provinces,
      battles: [...battles, newBattle],
    );
  }
} 