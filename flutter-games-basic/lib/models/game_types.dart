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

class Army {
  final String id;
  final String nationTag;
  final int size;

  const Army({
    required this.id,
    required this.nationTag,
    required this.size,
  });

  Army copyWith({
    String? id,
    String? nationTag,
    int? size,
  }) {
    return Army(
      id: id ?? this.id,
      nationTag: nationTag ?? this.nationTag,
      size: size ?? this.size,
    );
  }
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
  final List<Army> armies;  // Changed from int army to List<Army>
  final String owner;  // Nation tag that owns this province
  final List<String> borderingProvinces;  // IDs of provinces that border this one

  const Province({
    required this.id,
    required this.name,
    required this.path,
    required this.population,
    required this.goldIncome,
    required this.industry,
    required this.buildings,
    required this.resourceType,
    required this.armies,  // Updated parameter
    required this.owner,
    this.borderingProvinces = const [],  // Default to empty list
  });

  // Helper method to get total army size
  int get totalArmySize => armies.fold(0, (sum, army) => sum + army.size);

  // Helper method to get armies by nation
  List<Army> getArmiesByNation(String nationTag) => 
    armies.where((a) => a.nationTag == nationTag).toList();

  Province copyWith({
    String? id,
    String? name,
    String? path,
    int? population,
    int? goldIncome,
    int? industry,
    List<Building>? buildings,
    ResourceType? resourceType,
    List<Army>? armies,  // Updated parameter
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
      armies: armies ?? this.armies,  // Updated parameter
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
  final bool willStartBattle;
  final String nationTag;  // Added to track the nation of the moving army

  const Movement({
    required this.originProvinceId,
    required this.destinationProvinceId,
    required this.daysLeft,
    required this.armySize,
    this.willStartBattle = false,
    required this.nationTag,  // Required parameter for the nation tag
  });

  Movement copyWith({
    String? originProvinceId,
    String? destinationProvinceId,
    int? daysLeft,
    int? armySize,
    bool? willStartBattle,
    String? nationTag,
  }) {
    return Movement(
      originProvinceId: originProvinceId ?? this.originProvinceId,
      destinationProvinceId: destinationProvinceId ?? this.destinationProvinceId,
      daysLeft: daysLeft ?? this.daysLeft,
      armySize: armySize ?? this.armySize,
      willStartBattle: willStartBattle ?? this.willStartBattle,
      nationTag: nationTag ?? this.nationTag,
    );
  }

  Map<String, dynamic> toJson() => {
        'originProvinceId': originProvinceId,
        'destinationProvinceId': destinationProvinceId,
        'daysLeft': daysLeft,
        'armySize': armySize,
        'willStartBattle': willStartBattle,
        'nationTag': nationTag,
      };

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
        originProvinceId: json['originProvinceId'] as String,
        destinationProvinceId: json['destinationProvinceId'] as String,
        daysLeft: json['daysLeft'] as int,
        armySize: json['armySize'] as int,
        willStartBattle: json['willStartBattle'] as bool? ?? false,
        nationTag: json['nationTag'] as String,
      );
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
    final total = nationProvinces.fold(0, (sum, id) {
      final province = allProvinces.where((p) => p.id == id).firstOrNull;
      if (province == null) {
        print('Warning: Province $id not found for nation $nationTag');
      }
      return sum + (province?.population ?? 0);
    });
    return total;
  }
  
  int getTotalGoldIncome(List<Province> allProvinces) {
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
      sum + (allProvinces.where((p) => p.id == id).firstOrNull?.armies.length ?? 0));
  
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
  final bool isActive;
  final int attackerCasualties;
  final int defenderCasualties;

  const Battle({
    required this.provinceId,
    required this.attackerTag,
    required this.defenderTag,
    required this.attackerArmy,
    required this.defenderArmy,
    this.isActive = true,
    this.attackerCasualties = 0,
    this.defenderCasualties = 0,
  });

  Battle copyWith({
    String? provinceId,
    String? attackerTag,
    String? defenderTag,
    int? attackerArmy,
    int? defenderArmy,
    bool? isActive,
    int? attackerCasualties,
    int? defenderCasualties,
  }) {
    return Battle(
      provinceId: provinceId ?? this.provinceId,
      attackerTag: attackerTag ?? this.attackerTag,
      defenderTag: defenderTag ?? this.defenderTag,
      attackerArmy: attackerArmy ?? this.attackerArmy,
      defenderArmy: defenderArmy ?? this.defenderArmy,
      isActive: isActive ?? this.isActive,
      attackerCasualties: attackerCasualties ?? this.attackerCasualties,
      defenderCasualties: defenderCasualties ?? this.defenderCasualties,
    );
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
  final List<Battle> battles;
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
    List<Battle>? battles,
  }) : 
    battles = battles ?? [],
    _lastGainUpdateMonth = DateTime(1914, 1, 1).add(Duration(days: date)).month;

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
    print("\n=== PROCESSING MOVEMENTS ===");
    final updatedNations = nations.map((nation) {
      final updatedMovements = <Movement>[];
      final newBattles = <Battle>[];

      for (final movement in nation.movements) {
        if (movement.daysLeft > 1) {
          // Movement continues
          updatedMovements.add(movement.copyWith(daysLeft: movement.daysLeft - 1));
        } else {
          // Movement completes
          final targetProvince = provinces.firstWhere((p) => p.id == movement.destinationProvinceId);
          final isHostileMove = nation.atWarWith.contains(targetProvince.owner);

          if (isHostileMove && targetProvince.armies.isNotEmpty) {
            // Start a battle - don't remove this movement yet as we'll handle it in the battle processing
            print("Creating battle: ${nation.nationTag} -> ${targetProvince.owner} at ${targetProvince.name}");
            newBattles.add(Battle(
              provinceId: movement.destinationProvinceId,
              attackerTag: nation.nationTag,
              defenderTag: targetProvince.owner,
              attackerArmy: movement.armySize,
              defenderArmy: targetProvince.totalArmySize,
              isActive: true,
            ));
          }
          // Don't add completed movements to the updated list - they will be processed below
        }
      }

      return nation.copyWith(movements: updatedMovements);
    }).toList();

    // Map to track changes needed for each province
    final provinceArmyChanges = <String, List<Army>>{};
    
    // Process completed movements that don't result in battles
    for (final nation in nations) {
      for (final movement in nation.movements) {
        if (movement.daysLeft <= 1) {
          final targetProvince = provinces.firstWhere((p) => p.id == movement.destinationProvinceId);
          final isHostileMove = nation.atWarWith.contains(targetProvince.owner);
          
          // Skip movements that will lead to battles - we handle those in battle processing
          if (isHostileMove && targetProvince.armies.isNotEmpty) {
            continue;
          }
          
          print("Completing movement: ${nation.nationTag} from ${movement.originProvinceId} to ${movement.destinationProvinceId} (${movement.armySize} troops)");
          
          // Get the current armies at the destination
          List<Army> destArmies = provinceArmyChanges[movement.destinationProvinceId] ?? 
                       List.from(provinces.firstWhere((p) => p.id == movement.destinationProvinceId).armies);
          
          // Create a new army at the destination
          final newArmy = Army(
            id: 'army_${DateTime.now().millisecondsSinceEpoch}_${nation.nationTag}',
            nationTag: nation.nationTag,
            size: movement.armySize,
          );
          
          // Add the new army to the destination
          provinceArmyChanges[movement.destinationProvinceId] = [...destArmies, newArmy];
          
          // Mark the origin province for clearing only if we don't already have a change
          if (!provinceArmyChanges.containsKey(movement.originProvinceId)) {
            // Get current armies and remove only those from the moving nation
            final originProvince = provinces.firstWhere((p) => p.id == movement.originProvinceId);
            final remainingArmies = originProvince.armies.where((a) => a.nationTag != nation.nationTag).toList();
            provinceArmyChanges[movement.originProvinceId] = remainingArmies;
          }
        }
      }
    }
    
    // Apply province army changes
    final updatedProvinces = provinces.map((province) {
      if (provinceArmyChanges.containsKey(province.id)) {
        print("Updating province ${province.id} (${province.name}): ${province.armies.length} armies -> ${provinceArmyChanges[province.id]!.length} armies");
        for (final army in provinceArmyChanges[province.id]!) {
          print("  Army: ${army.id}, Nation: ${army.nationTag}, Size: ${army.size}");
        }
        return province.copyWith(armies: provinceArmyChanges[province.id]!);
      }
      return province;
    }).toList();

    // Collect all battles that will start
    final allNewBattles = <Battle>[];
    for (final nation in nations) {
      for (final movement in nation.movements.where((m) => m.daysLeft <= 1)) {
        final targetProvince = provinces.firstWhere((p) => p.id == movement.destinationProvinceId);
        final isHostileMove = nation.atWarWith.contains(targetProvince.owner);
        
        if (isHostileMove && targetProvince.armies.isNotEmpty) {
          final existingBattle = allNewBattles.firstWhere(
            (b) => b.provinceId == movement.destinationProvinceId,
            orElse: () => Battle(
              provinceId: movement.destinationProvinceId,
              attackerTag: nation.nationTag,
              defenderTag: targetProvince.owner,
              attackerArmy: movement.armySize,
              defenderArmy: targetProvince.totalArmySize,
              isActive: true,
            ),
          );
          
          if (!allNewBattles.contains(existingBattle)) {
            allNewBattles.add(existingBattle);
          }
        }
      }
    }
    
    print("Updated provinces with armies: ${updatedProvinces.where((p) => p.armies.isNotEmpty).length}");
    print("New battles: ${allNewBattles.length}");
    print("=== END PROCESSING MOVEMENTS ===\n");

    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: updatedNations,
      provinces: updatedProvinces,
      battles: [...battles.where((b) => b.isActive), ...allNewBattles],
    );
  }

  Game _processBattles(Game game) {
    print("\n=== PROCESSING BATTLES ===");
    final updatedBattles = <Battle>[];
    final updatedProvinces = List<Province>.from(game.provinces);
    final updatedNations = List<Nation>.from(game.nations);
    
    for (final battle in game.battles) {
      if (!battle.isActive) {
        updatedBattles.add(battle);
        continue;
      }

      // Get the province where the battle is happening
      final provinceIndex = updatedProvinces.indexWhere((p) => p.id == battle.provinceId);
      if (provinceIndex == -1) {
        // Province not found, skip this battle
        updatedBattles.add(battle);
        continue;
      }
      
      final province = updatedProvinces[provinceIndex];

      // Debug logging for active battles
      print('\n=== Battle Update ===');
      print('Location: ${province.name}');
      print('Attacker: ${updatedNations.firstWhere((n) => n.nationTag == battle.attackerTag).name}');
      print('Attacker Army: ${battle.attackerArmy}');
      print('Attacker Casualties: ${battle.attackerCasualties}');
      print('Defender: ${updatedNations.firstWhere((n) => n.nationTag == battle.defenderTag).name}');
      print('Defender Army: ${battle.defenderArmy}');
      print('Defender Casualties: ${battle.defenderCasualties}');

      // Simulate battle tick - each side loses troops
      final newAttackerArmy = max(0, battle.attackerArmy - 5000);
      final newDefenderArmy = max(0, battle.defenderArmy - 4000); // Defender has a slight advantage
      
      final newAttackerCasualties = battle.attackerCasualties + (battle.attackerArmy - newAttackerArmy);
      final newDefenderCasualties = battle.defenderCasualties + (battle.defenderArmy - newDefenderArmy);

      // Check if battle is over
      final isBattleOver = newAttackerArmy == 0 || newDefenderArmy == 0;
      
      final updatedBattle = battle.copyWith(
        attackerArmy: newAttackerArmy,
        defenderArmy: newDefenderArmy,
        attackerCasualties: newAttackerCasualties,
        defenderCasualties: newDefenderCasualties,
        isActive: !isBattleOver,
      );

      if (isBattleOver) {
        print('\n=== Battle Ended ===');
        final attackerWon = newDefenderArmy == 0;
        print('Winner: ${attackerWon ? "Attacker" : "Defender"}');
        print('Final Attacker Casualties: ${newAttackerCasualties}');
        print('Final Defender Casualties: ${newDefenderCasualties}');
        print('=== Battle Summary End ===\n');

        // Update province ownership and armies based on battle outcome
        if (attackerWon) {
          // Attacker won - change province ownership and place remaining attacker army
          final newArmy = Army(
            id: 'army_conquest_${DateTime.now().millisecondsSinceEpoch}',
            nationTag: battle.attackerTag,
            size: newAttackerArmy,
          );
          
          // Update the attacker nation's province list
          final attackerIndex = updatedNations.indexWhere((n) => n.nationTag == battle.attackerTag);
          if (attackerIndex != -1) {
            final attackerNation = updatedNations[attackerIndex];
            if (!attackerNation.nationProvinces.contains(battle.provinceId)) {
              updatedNations[attackerIndex] = attackerNation.copyWith(
                nationProvinces: [...attackerNation.nationProvinces, battle.provinceId],
              );
            }
          }
          
          // Update the defender nation's province list
          final defenderIndex = updatedNations.indexWhere((n) => n.nationTag == battle.defenderTag);
          if (defenderIndex != -1) {
            final defenderNation = updatedNations[defenderIndex];
            updatedNations[defenderIndex] = defenderNation.copyWith(
              nationProvinces: defenderNation.nationProvinces.where((p) => p != battle.provinceId).toList(),
            );
          }
          
          // Update the province
          updatedProvinces[provinceIndex] = province.copyWith(
            owner: battle.attackerTag,
            armies: newAttackerArmy > 0 ? [newArmy] : [],
          );
          
          print("Province ${province.name} conquered by ${battle.attackerTag}");
          if (newAttackerArmy > 0) {
            print("Placing army of size ${newArmy.size} in province");
          }
        } else {
          // Defender won - keep ownership but update defender army
          // Filter out any attacker armies that might exist
          final defenderArmies = province.armies.where((a) => a.nationTag == battle.defenderTag).toList();
          
          if (defenderArmies.isNotEmpty && newDefenderArmy > 0) {
            // Update the first defender army's size
            final updatedArmy = defenderArmies.first.copyWith(size: newDefenderArmy);
            
            // Keep any other armies that belong to the defender
            final otherDefenderArmies = defenderArmies.sublist(min(1, defenderArmies.length));
            
            // Keep any armies belonging to nations that aren't part of this battle
            final otherArmies = province.armies.where((a) => 
              a.nationTag != battle.attackerTag && a.nationTag != battle.defenderTag).toList();
            
            updatedProvinces[provinceIndex] = province.copyWith(
              armies: [updatedArmy, ...otherDefenderArmies, ...otherArmies],
            );
            
            print("Defender ${battle.defenderTag} kept province ${province.name}");
            print("Updated defender army to size ${updatedArmy.size}");
          } else if (newDefenderArmy > 0) {
            // No existing defender armies, create a new one
            final newArmy = Army(
              id: 'army_defense_${DateTime.now().millisecondsSinceEpoch}',
              nationTag: battle.defenderTag,
              size: newDefenderArmy,
            );
            
            // Keep any armies belonging to nations that aren't part of this battle
            final otherArmies = province.armies.where((a) => 
              a.nationTag != battle.attackerTag && a.nationTag != battle.defenderTag).toList();
            
            updatedProvinces[provinceIndex] = province.copyWith(
              armies: [newArmy, ...otherArmies],
            );
            
            print("Defender ${battle.defenderTag} kept province ${province.name}");
            print("Created new defender army of size ${newArmy.size}");
          } else {
            // No defender armies left (should not happen since defender won)
            // Keep any armies belonging to nations that aren't part of this battle
            final otherArmies = province.armies.where((a) => 
              a.nationTag != battle.attackerTag && a.nationTag != battle.defenderTag).toList();
            
            updatedProvinces[provinceIndex] = province.copyWith(
              armies: otherArmies,
            );
            
            print("Defender ${battle.defenderTag} kept province ${province.name} but has no armies left");
          }
        }
      } else {
        print('=== Battle Continues ===\n');
      }

      updatedBattles.add(updatedBattle);
    }

    print("Battles remaining active: ${updatedBattles.count((b) => b.isActive)}");
    print("=== END PROCESSING BATTLES ===\n");
    
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
    final targetProvince = provinces.firstWhere((p) => p.id == provinceId);
    
    print('\n=== Starting New Battle ===');
    print('Location: ${targetProvince.name}');
    print('Attacker: ${nations.firstWhere((n) => n.nationTag == attackerTag).name} ($attackerArmy troops)');
    print('Defender: ${nations.firstWhere((n) => n.nationTag == defenderTag).name} ($defenderArmy troops)');
    print('=== Battle Started ===\n');

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
      battles: battles,
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
      battles: battles,
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
      battles: battles,
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
      battles: battles,
    );
  }

  Game modifyNationGold(String nationTag, int goldChange) {
    return Game(
      id: id,
      gameName: gameName,
      date: date,
      mapName: mapName,
      playerNationTag: playerNationTag,
      nations: nations.map((nation) {
        if (nation.nationTag == nationTag) {
          return nation.copyWith(
            gold: nation.gold + goldChange,
          );
        }
        return nation;
      }).toList(),
      provinces: provinces,
      battles: battles,
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