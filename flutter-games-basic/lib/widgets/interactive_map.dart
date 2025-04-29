// This widget displays the map of the world in SVG format 
// It takes a game object and adjusts its map using the data
// It then displays the map data in an SVG format
// It also displays the player's nation on the map

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_types.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'province_details_popup.dart';
import 'nation_details_popup.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';


class InteractiveMap extends StatefulWidget {
  final List<Province> provinces;
  final List<Nation> nations;
  final Function(Game) onGameUpdate;
  final Function(Movement)? onMovementCreated;
  final Game game;

  const InteractiveMap({
    super.key, 
    required this.provinces,
    required this.nations,
    required this.onGameUpdate,
    required this.game,
    this.onMovementCreated,
  });

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> with SingleTickerProviderStateMixin {
  List<Region> regions = [];
  Region? selectedRegion;
  num rerenderVariable = 0;
  bool _isLoading = true;
  bool _showProvinceDetails = false;
  bool _showNationDetails = false;
  Nation? _selectedNation;
  bool _isMovementMode = false;
  String? _movementOriginId;
  String? _movementTargetId;
  DateTime? _lastTapTime;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final Map<String, Path> _cachedPaths = {};
  final Map<String, Color> _cachedColors = {};
  Map<String, ui.Image> flagImages = {};
  TransformationController transformationController = TransformationController();
  final Map<String, Rect> _cachedBounds = {};
  final Map<String, TextPainter> _cachedTextPainters = {};
  final Map<String, bool> _cachedVisibility = {};
  static const double MIN_TEXT_SCALE = 4.0;

  // Add viewport culling optimization
  final GlobalKey _interactiveViewerKey = GlobalKey();
  Rect? _lastViewport;
  Matrix4? _lastTransform;
  bool _isInteracting = false;
  Timer? _interactionTimer;

  final Map<String, Color> _highlightedProvinces = {};

  // Helper method to convert hex color string to Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Helper method to get province color based on ownership
  Color _getProvinceColor(String regionId) {
    if (_cachedColors.containsKey(regionId)) {
      return _cachedColors[regionId]!;
    }

    final province = _getProvinceForRegion(regionId);
    if (province.id.isEmpty) {
      _cachedColors[regionId] = Colors.grey;
      return Colors.grey;
    }

    final ownerNation = _getNationForProvince(province);
    if (ownerNation == null) {
      _cachedColors[regionId] = Colors.grey;
      return Colors.grey;
    }

    final color = _hexToColor(ownerNation.hexColor);
    _cachedColors[regionId] = color;
    return color;
  }

  Province _getProvinceForRegion(String regionId) {
    return widget.game.provinces.firstWhere(
      (p) => p.id == regionId,
      orElse: () => Province(
        id: '',
        name: '',
        path: '',
        population: 0,
        goldIncome: 0,
        industry: 0,
        buildings: [],
        resourceType: ResourceType.none,
        armies: [],
        owner: '',
      ),
    );
  }

  Nation? _getNationForProvince(Province province) {
    if (province.owner.isEmpty) return null;
    return widget.game.nations.firstWhere(
      (n) => n.nationTag == province.owner,
      orElse: () => Nation(
        nationTag: '',
        name: '',
        color: '',
        hexColor: '',
        nationProvinces: [],
        allies: [],
        borderProvinces: [],
        gold: 0,
        researchPoints: 0,
        currentResearchId: null,
        currentResearchProgress: 0,
        buildQueue: null,
        isAI: false,
        armyReserve: 0,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadRegions();
    _loadFlagImages();
   
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    // Set initial transformation to center the map
    transformationController = TransformationController();
    transformationController.value = Matrix4.identity()
      ..scale(4.0)  // Initial zoom level
      ..translate(-550.0, 0.0);  // Center the map

    // Listen to transformation changes
    transformationController.addListener(_onTransformationChange);
  }

  @override
  void dispose() {
    print('=== InteractiveMap dispose ===');
    transformationController.removeListener(_onTransformationChange);
    _interactionTimer?.cancel();
    _fadeController.dispose();
    _cachedPaths.clear();
    _cachedColors.clear();
    super.dispose();
    print('=== InteractiveMap dispose Complete ===');
  }

  void _onTransformationChange() {
    // Debounce rapid transformation changes
    _isInteracting = true;
    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isInteracting = false;
        });
      }
    });

    // Only update if transformation has changed significantly
    final newTransform = transformationController.value;
    if (_lastTransform != null) {
      final scale = newTransform.getMaxScaleOnAxis();
      final lastScale = _lastTransform!.getMaxScaleOnAxis();
      if ((scale - lastScale).abs() < 0.01) {
        return;
      }
    }
    _lastTransform = newTransform.clone();
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadRegions() async {
    const path = 'assets/svg/world_states_map.svg';
    final content = await rootBundle.loadString(path);
    
    final document = XmlDocument.parse(content);
    final paths = document.findAllElements('path');
    
    final List<Region> loadedRegions = [];
    
    for (final element in paths) {
      final partId = element.getAttribute('id') ?? '';
      if (partId.isEmpty) {
        continue;
      }
      final partPath = element.getAttribute('d').toString() ?? '';
      final region = Region(id: partId, path: partPath);
      loadedRegions.add(region);
      
      // Pre-cache paths and colors
      _cachedPaths[partId] = parseSvgPathData(partPath);
      _getProvinceColor(partId);
    }
    
    setState(() {
      regions = loadedRegions;
      _isLoading = false;
    });
    _fadeController.forward();
  }

  Future<void> _loadFlagImages() async {
    for (final nation in widget.game.nations) {
      try {
        final data = await rootBundle.load('assets/flags/${nation.nationTag.toLowerCase()}.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        flagImages[nation.nationTag.toLowerCase()] = frame.image;
      } catch (e) {
        print('Error loading flag for ${nation.nationTag}: $e');
      }
    }
    setState(() {}); // Trigger rebuild once flags are loaded
  }

  double get currentScale {
    final matrix = transformationController.value;
    // Scale is the first element in the matrix
    return matrix.getMaxScaleOnAxis();
  }

  void _startMovement() {
    if (selectedRegion == null) return;
    
    final province = _getProvinceForRegion(selectedRegion!.id);
    if (province.armies.isEmpty) return;
    
    setState(() {
      _isMovementMode = true;
      _showProvinceDetails = false;
      _movementOriginId = selectedRegion?.id;
    });
  }

  void _cancelMovement() {
    setState(() {
      _isMovementMode = false;
      _movementOriginId = null;
    });
  }

  void _handleMovement(String destinationId) {
    if (_movementOriginId == null) return;
    
    final originProvince = _getProvinceForRegion(_movementOriginId!);
    final destProvince = _getProvinceForRegion(destinationId);
    
    if (!_canSelectProvince(originProvince) || !_canMoveToProvince(destProvince)) return;
    
    final originPath = _cachedPaths[_movementOriginId];
    final destPath = _cachedPaths[destinationId];
    if (originPath != null && destPath != null) {
      final daysRequired = calculateMovementDays(
        originPath.getBounds().center,
        destPath.getBounds().center,
      );
      _startMovementToProvince(destinationId, daysRequired);
    }
  }

  String? _getMovementInfo(String provinceId) {
    for (final nation in widget.game.nations) {
      final movement = nation.movements.firstWhere(
        (m) => m.originProvinceId == provinceId,
        orElse: () => Movement(
          originProvinceId: '',
          destinationProvinceId: '',
          daysLeft: 0,
          armySize: 0,
          nationTag: '',
        ),
      );
      if (movement.originProvinceId.isNotEmpty) {
        final destProvince = widget.game.provinces.firstWhere((p) => p.id == movement.destinationProvinceId);
        return 'Moving to ${destProvince.name} in ${movement.daysLeft} days';
      }
    }
    return null;
  }

  int _getRemainingDays(String provinceId) {
    for (final nation in widget.game.nations) {
      final movement = nation.movements.firstWhere(
        (m) => m.originProvinceId == provinceId,
        orElse: () => Movement(
          originProvinceId: '',
          destinationProvinceId: '',
          daysLeft: 0,
          armySize: 0,
          nationTag: '',
        ),
      );
      if (movement.originProvinceId.isNotEmpty) {
        return movement.daysLeft;
      }
    }
    return 0;
  }

  // Add movement speed calculation
  int calculateMovementDays(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    // Use a multiplier of 1 day per unit of distance
    print("days: ${max(1, (distance * 1).round())}");
    return max(1, (distance * 1).round());
  }

  bool _canSeeArmyInProvince(Province province) {
    // Can always see armies in your own provinces
    if (province.owner == widget.game.playerNationTag) {
      return true;
    }

    // Get the player's nation
    final playerNation = widget.game.nations.firstWhere(
      (n) => n.nationTag == widget.game.playerNationTag,
    );

    // Check if this province borders any of our provinces
    for (final playerProvinceId in playerNation.nationProvinces) {
      final playerProvince = widget.game.provinces.firstWhere(
        (p) => p.id == playerProvinceId,
        orElse: () => Province(
          id: '',
          name: '',
          path: '',
          population: 0,
          goldIncome: 0,
          industry: 0,
          buildings: [],
          resourceType: ResourceType.none,
          armies: [],
          owner: '',
          borderingProvinces: [],
        ),
      );

      // Check if this province is in our bordering provinces
      if (playerProvince.borderingProvinces.contains(province.id)) {
        return true;
      }

      // Check if our province is in this province's bordering provinces
      if (province.borderingProvinces.contains(playerProvince.id)) {
        return true;
      }
    }

    return false;
  }

  bool _canSelectProvince(Province province) {
    // Can only select and move armies in provinces we own
    return province.owner == widget.game.playerNationTag;
  }

  bool _canMoveToProvince(Province targetProvince) {
    if (selectedRegion == null) return false;

    // Get the origin province
    final originProvince = widget.game.provinces.firstWhere(
      (p) => p.id == selectedRegion!.id,
      orElse: () => Province(
        id: '',
        name: '',
        path: '',
        population: 0,
        goldIncome: 0,
        industry: 0,
        buildings: [],
        resourceType: ResourceType.none,
        armies: [],
        owner: '',
        borderingProvinces: [],
      ),
    );

    // Can only move to provinces that border the origin province
    if (!originProvince.borderingProvinces.contains(targetProvince.id)) {
      return false;
    }

    // Can move to own provinces or allied provinces
    if (targetProvince.owner == widget.game.playerNationTag || 
        widget.game.playerNation.allies.contains(targetProvince.owner)) {
      return true;
    }

    // Can move to enemy provinces if at war and we border them
    return widget.game.playerNation.atWarWith.contains(targetProvince.owner);
  }

  bool _isHostileMovement(Province targetProvince) {
    return widget.game.playerNation.atWarWith.contains(targetProvince.owner);
  }

  bool _hasOutgoingMovement(String provinceId) {
    // Check if there's any movement originating from this province
    for (final nation in widget.game.nations) {
      if (nation.movements.any((m) => m.originProvinceId == provinceId)) {
        return true;
      }
    }
    return false;
  }

  void _handleRegionTap(String? regionId) {
    print('=== Handling Region Tap ===');
    if (regionId == null) {
      print('Clearing selection');
      setState(() {
        selectedRegion = null;
        _showProvinceDetails = false;
        _movementTargetId = null;
      });
      return;
    }

    final targetProvince = widget.game.provinces.firstWhere(
      (p) => p.id == regionId,
      orElse: () => Province(
        id: '',
        name: '',
        path: '',
        population: 0,
        goldIncome: 0,
        industry: 0,
        buildings: [],
        resourceType: ResourceType.none,
        armies: [],
        owner: '',
        borderingProvinces: [],
      ),
    );
    
    final targetNation = _getNationForProvince(targetProvince);
    
    final playerNation = widget.game.nations.firstWhere(
      (n) => n.nationTag == widget.game.playerNationTag,
      orElse: () => Nation(
        nationTag: '',
        name: '',
        color: '',
        hexColor: '',
        nationProvinces: [],
        allies: [],
        borderProvinces: [],
        gold: 0,
        researchPoints: 0,
        currentResearchId: null,
        currentResearchProgress: 0,
        buildQueue: null,
        isAI: false,
        armyReserve: 0,
      ),
    );
    
    print('Player nation: ${playerNation.nationTag}');
    
    setState(() {
      // If clicking the same province that's already selected, unselect it
      if (selectedRegion != null && regionId == selectedRegion!.id) {
        print('Deselecting current province');
        selectedRegion = null;
        _showProvinceDetails = false;
        _showNationDetails = false;
        _movementTargetId = null;
        return;
      }

      if (selectedRegion != null && regionId != selectedRegion!.id) {
        final originProvince = widget.game.provinces.firstWhere(
          (p) => p.id == selectedRegion!.id,
          orElse: () => Province(
            id: '',
            name: '',
            path: '',
            population: 0,
            goldIncome: 0,
            industry: 0,
            buildings: [],
            resourceType: ResourceType.none,
            armies: [],
            owner: '',
            borderingProvinces: [],
          ),
        );
        print('Checking movement from ${originProvince.id} to ${targetProvince.id}');
        
        // Only allow movement if we own the origin province
        if (!_hasOutgoingMovement(selectedRegion!.id) && 
            originProvince.armies.isNotEmpty && 
            _canSelectProvince(originProvince) && 
            _canMoveToProvince(targetProvince)) {
          // If this is a new target, set it as movement target
          if (_movementTargetId != regionId) {
            print('Setting movement target to $regionId');
            _movementTargetId = regionId;
            return;
          }
        }
      }

      // If we're clicking the target province again, confirm movement
      if (_movementTargetId == regionId && !_hasOutgoingMovement(selectedRegion!.id)) {
        print('Confirming movement to $regionId');
        final originPath = _cachedPaths[selectedRegion!.id];
        final destPath = _cachedPaths[regionId];
        if (originPath != null && destPath != null) {
          final daysRequired = calculateMovementDays(
            originPath.getBounds().center,
            destPath.getBounds().center,
          );
          _startMovementToProvince(regionId, daysRequired);
        }
        // Clear selection after movement starts
        selectedRegion = null;
        _showProvinceDetails = false;
        _movementTargetId = null;
        return;
      }

      // Normal province selection - can select any province but can only move armies from owned provinces
        selectedRegion = Region(id: regionId, path: '');
        _showProvinceDetails = false;
        _showNationDetails = false;
        _movementTargetId = null;

      // Show nation details for foreign provinces
      if (targetNation != null && targetNation.nationTag != playerNation.nationTag) {
        print('Showing nation details for ${targetNation.nationTag}');
          _showNationDetails = true;
          _selectedNation = targetNation;
      }
    });
    print('=== Province Selection Complete ===');
  }

  void _startMovementToProvince(String destinationId, int daysRequired) {
    if (selectedRegion == null) return;
    
    final originProvince = _getProvinceForRegion(selectedRegion!.id);
    if (originProvince.armies.isEmpty) return;

    print('\n=== DEBUG: Starting Movement ===');
    print('From province: ${originProvince.id} (${originProvince.name})');
    print('To province: ${destinationId}');
    print('Origin province armies before movement:');
    for (final army in originProvince.armies) {
      print('  Army ID: ${army.id}, Nation: ${army.nationTag}, Size: ${army.size}');
    }
    print('Total army size: ${originProvince.totalArmySize}');

    final targetProvince = _getProvinceForRegion(destinationId);
    final isHostileMove = _isHostileMovement(targetProvince);

    final totalArmySize = originProvince.armies.fold<int>(0, (sum, army) => sum + army.size);

    if (isHostileMove && targetProvince.armies.isNotEmpty) {
      // Start movement that will lead to a battle
      final updatedNations = widget.game.nations.map((nation) {
        if (nation.nationTag == widget.game.playerNationTag) {
          // Create a movement
          final movement = Movement(
            originProvinceId: selectedRegion!.id,
            destinationProvinceId: destinationId,
            daysLeft: daysRequired,
            armySize: totalArmySize,
            willStartBattle: true,
            nationTag: nation.nationTag,
          );
          print('Creating movement: ${movement.originProvinceId} -> ${movement.destinationProvinceId} (Army size: ${movement.armySize})');
          return nation.copyWith(
            movements: [
              ...nation.movements,
              movement,
            ],
          );
        }
        return nation;
      }).toList();

      // Remove army from origin province
      final updatedProvinces = widget.game.provinces.map((p) {
        if (p.id == selectedRegion!.id) {
          print('Removing armies from origin province: ${p.id}');
          return p.copyWith(armies: []);
        }
        return p;
      }).toList();

      final updatedGame = Game(
        id: widget.game.id,
        gameName: widget.game.gameName,
        date: widget.game.date,
        mapName: widget.game.mapName,
        playerNationTag: widget.game.playerNationTag,
        nations: updatedNations,
        provinces: updatedProvinces,
        battles: widget.game.battles,
      );

      widget.onGameUpdate(updatedGame);
    } else {
      // Normal movement
      final updatedNations = widget.game.nations.map((nation) {
        if (nation.nationTag == widget.game.playerNationTag) {
          // Create a movement
          final movement = Movement(
            originProvinceId: selectedRegion!.id,
            destinationProvinceId: destinationId,
            daysLeft: daysRequired,
            armySize: totalArmySize,
            nationTag: nation.nationTag,
          );
          print('Creating movement: ${movement.originProvinceId} -> ${movement.destinationProvinceId} (Army size: ${movement.armySize})');
          return nation.copyWith(
            movements: [
              ...nation.movements,
              movement,
            ],
          );
        }
        return nation;
      }).toList();

      // Remove army from origin province
      final updatedProvinces = widget.game.provinces.map((p) {
        if (p.id == selectedRegion!.id) {
          print('Removing armies from origin province: ${p.id}');
          return p.copyWith(armies: []);
        }
        return p;
      }).toList();

      final updatedGame = Game(
        id: widget.game.id,
        gameName: widget.game.gameName,
        date: widget.game.date,
        mapName: widget.game.mapName,
        playerNationTag: widget.game.playerNationTag,
        nations: updatedNations,
        provinces: updatedProvinces,
        battles: widget.game.battles,
      );

      widget.onGameUpdate(updatedGame);
    }

    setState(() {
      _isMovementMode = false;
      selectedRegion = null;
    });
    print('=== Movement Setup Complete ===\n');
  }

  void _cancelMovementFromProvince(String provinceId) {
    print('=== Canceling Movement ===');
    print('From province: $provinceId');
    
    try {
      final updatedNations = widget.game.nations.map((nation) {
        if (nation.nationTag == widget.game.playerNationTag) {
          final updatedMovements = nation.movements.where((m) => m.originProvinceId != provinceId).toList();
          print('Removed movement from ${nation.nationTag}');
          return nation.copyWith(movements: updatedMovements);
        }
        return nation;
      }).toList();

      final updatedGame = Game(
        id: widget.game.id,
        gameName: widget.game.gameName,
        date: widget.game.date,
        mapName: widget.game.mapName,
        playerNationTag: widget.game.playerNationTag,
        nations: updatedNations,
        provinces: widget.game.provinces,
      );

      widget.onGameUpdate(updatedGame);
      print('=== Movement Canceled ===');
    } catch (e) {
      print('Error canceling movement: $e');
      print('Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error canceling movement: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Add this new function
  void _triggerRepaint() {
    print('Forcing map repaint...');
    if (mounted) {
      var currentSelectedRegion = selectedRegion;
      setState(() {
        // This will force the MapPainter to repaint
        selectedRegion = selectedRegion == null ? Region(id: '', path: '') : null;
      });
      setState(() {
        // This will force the MapPainter to repaint
        rerenderVariable++;
      });
    }
  }

  @override
  void didUpdateWidget(InteractiveMap oldWidget) {
    print('=== InteractiveMap didUpdateWidget ===');
    super.didUpdateWidget(oldWidget);
    
    // Check if provinces, movements, or battles have changed
    final oldMovementCount = oldWidget.game.nations.fold<int>(0, (count, nation) => count + nation.movements.length);
    final newMovementCount = widget.game.nations.fold<int>(0, (count, nation) => count + nation.movements.length);
    
    final oldBattleCount = oldWidget.game.battles.length;
    final oldActiveBattleCount = oldWidget.game.battles.where((b) => b.isActive).length;
    
    final newBattleCount = widget.game.battles.length;
    final newActiveBattleCount = widget.game.battles.where((b) => b.isActive).length;
    
    print('Movement count: $oldMovementCount -> $newMovementCount');
    print('Battle count: $oldBattleCount -> $newBattleCount');
    print('Active battle count: $oldActiveBattleCount -> $newActiveBattleCount');
    
    // Check if battles have changed (created, completed, or updated)
    bool battleChanged = false;
    
    // New battle created
    if (newBattleCount > oldBattleCount) {
      print('\n=== New battles created ===');
      battleChanged = true;
    }
    
    // Battle completed
    if (oldActiveBattleCount > newActiveBattleCount) {
      print('\n=== Battles completed ===');
      battleChanged = true;
    }
    
    // Battle updated (same number of active battles, but battles have progressed)
    if (oldActiveBattleCount == newActiveBattleCount && oldActiveBattleCount > 0) {
      // Check if any battle casualties changed
      bool casualtiesChanged = false;
      
      for (final oldBattle in oldWidget.game.battles.where((b) => b.isActive)) {
        final newBattle = widget.game.battles.firstWhere(
          (b) => b.provinceId == oldBattle.provinceId && b.isActive,
          orElse: () => Battle(
            provinceId: '',
            attackerTag: '',
            defenderTag: '',
            attackerArmy: 0,
            defenderArmy: 0,
            isActive: false,
          ),
        );
        
        if (newBattle.provinceId.isNotEmpty &&
            (oldBattle.attackerArmy != newBattle.attackerArmy ||
             oldBattle.defenderArmy != newBattle.defenderArmy ||
             oldBattle.attackerCasualties != newBattle.attackerCasualties ||
             oldBattle.defenderCasualties != newBattle.defenderCasualties)) {
          casualtiesChanged = true;
          print('\n=== Battle casualties changed ===');
          print('Province: ${newBattle.provinceId}');
          print('Attacker: ${oldBattle.attackerArmy} -> ${newBattle.attackerArmy}');
          print('Defender: ${oldBattle.defenderArmy} -> ${newBattle.defenderArmy}');
          break;
        }
      }
      
      if (casualtiesChanged) {
        battleChanged = true;
      }
    }
    
    // Check provinces with armies
    final provincesWithArmies = widget.game.provinces.where((p) => p.armies.isNotEmpty).toList();
    print('Provinces with armies: ${provincesWithArmies.length}');
    for (final province in provincesWithArmies) {
      print('  Province ${province.id} (${province.name}): ${province.armies.length} armies, total size: ${province.totalArmySize}');
      for (final army in province.armies) {
        print('    Army ID: ${army.id}, Nation: ${army.nationTag}, Size: ${army.size}');
      }
    }
    
    // Check for active battles
    if (widget.game.battles.any((b) => b.isActive)) {
      print('\n=== Active Battles ===');
      for (final battle in widget.game.battles.where((b) => b.isActive)) {
        final province = widget.game.provinces.firstWhere(
          (p) => p.id == battle.provinceId,
          orElse: () => Province(
            id: '',
            name: '',
            path: '',
            population: 0,
            goldIncome: 0,
            industry: 0,
            buildings: [],
            resourceType: ResourceType.none,
            armies: [],
            owner: '',
            borderingProvinces: [],
          ),
        );
        
        print('Battle in ${province.name}:');
        print('  Attacker: ${battle.attackerTag} (${battle.attackerArmy} troops)');
        print('  Defender: ${battle.defenderTag} (${battle.defenderArmy} troops)');
        print('  Casualties: ${battle.attackerCasualties} attackers, ${battle.defenderCasualties} defenders');
      }
      print('=== End Active Battles ===\n');
    }
    
    // Check if date changed or if movements have completed
    if (oldWidget.game.date != widget.game.date) {
      print('\n=== Movement Status for ${widget.game.date} ===');
      
      // Track active movements
      int activeMovements = 0;
      for (final nation in widget.game.nations) {
        if (nation.movements.isEmpty) continue;
        
        print('\nNation: ${nation.nationTag} (${nation.movements.length} movements)');
        for (final movement in nation.movements) {
          activeMovements++;
          print('  From: ${movement.originProvinceId}');
          print('  To: ${movement.destinationProvinceId}');
          print('  Army size: ${movement.armySize}');
          print('  Days left: ${movement.daysLeft}');
          
          // Check origin and destination provinces
          final originProvince = widget.game.provinces.firstWhere(
            (p) => p.id == movement.originProvinceId,
            orElse: () => Province(id: '', name: '', path: '', population: 0, goldIncome: 0, industry: 0, buildings: [], resourceType: ResourceType.none, armies: [], owner: '', borderingProvinces: []),
          );
          
          final destProvince = widget.game.provinces.firstWhere(
            (p) => p.id == movement.destinationProvinceId,
            orElse: () => Province(id: '', name: '', path: '', population: 0, goldIncome: 0, industry: 0, buildings: [], resourceType: ResourceType.none, armies: [], owner: '', borderingProvinces: []),
          );
          
          print('  Origin province (${originProvince.id}): ${originProvince.armies.length} armies, total size: ${originProvince.totalArmySize}');
          print('  Destination province (${destProvince.id}): ${destProvince.armies.length} armies, total size: ${destProvince.totalArmySize}');
        }
      }
      
      print('\nActive movements: $activeMovements');
      print('=== End Movement Status ===\n');
      
      // Check for movements that just completed
      final completedMovements = <String>[];
      
      // Check for movements that were about to complete in the previous state
      for (final nation in oldWidget.game.nations) {
        final completingMovements = nation.movements.where((m) => m.daysLeft <= 1).toList();
        for (final movement in completingMovements) {
          // Check if this movement is no longer in the current state
          final currentNation = widget.game.nations.firstWhere(
            (n) => n.nationTag == nation.nationTag,
            orElse: () => Nation(
              nationTag: '',
              name: '',
              color: '',
              hexColor: '',
              nationProvinces: [],
              allies: [],
              borderProvinces: [],
              gold: 0,
              researchPoints: 0,
              currentResearchId: null,
              currentResearchProgress: 0,
              buildQueue: null,
              isAI: false,
              movements: [],
              atWarWith: [],
              armyReserve: 0,
            ),
          );
          
          final movementStillExists = currentNation.movements.any(
            (m) => m.originProvinceId == movement.originProvinceId && 
                   m.destinationProvinceId == movement.destinationProvinceId
          );
          
          if (!movementStillExists) {
            print('Detected completed movement to ${movement.destinationProvinceId}');
            completedMovements.add(movement.destinationProvinceId);
          }
        }
      }
      
      // If there are any completed movements, trigger a repaint
      if (completedMovements.isNotEmpty) {
        print('\n=== Handling Completed Movements ===');
        print('Completed destinations: ${completedMovements.join(", ")}');
        print('Triggering repaint for completed movements');
        _triggerRepaint();
        print('=== Completed Movements Handled ===\n');
      }
    } else if (oldMovementCount > newMovementCount) {
      // Movement count decreased without a date change, which likely means battles finished
      print('\n=== Movement count decreased without date change ===');
      print('Likely battle completion or manual cancellation');
      print('Triggering repaint');
      _triggerRepaint();
      print('=== Repaint triggered ===\n');
    }
    
    // If battles have changed, trigger a repaint
    if (battleChanged) {
      print('\n=== Battle changes detected ===');
      print('Triggering repaint to update battle visualizations');
      _triggerRepaint();
      print('=== Battle repaint triggered ===\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading Map...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final selectedProvince = selectedRegion != null ? _getProvinceForRegion(selectedRegion!.id) : null;
    final selectedNation = selectedProvince != null && selectedProvince.id.isNotEmpty 
        ? _getNationForProvince(selectedProvince) 
        : null;


    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Invisible rerender helper
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(
              opacity: 0,
              child: Text(
                rerenderVariable.toString(),
                style: const TextStyle(fontSize: 0.1),
              ),
            ),
          ),
          Center(
            child: InteractiveViewer(
              key: _interactiveViewerKey,
              transformationController: transformationController,
              boundaryMargin: const EdgeInsets.all(8.0),
              minScale: 1.0,
              maxScale: 40.0,
              constrained: false,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: const Size(1200, 480),
                  painter: MapPainter(
                    regions: regions,
                    cachedPaths: _cachedPaths,
                    cachedColors: _cachedColors,
                    selectedRegionId: selectedRegion?.id,
                    onRegionSelected: _handleRegionTap,
                    game: widget.game,
                    scale: currentScale,
                    flagImages: flagImages,
                    isMovementMode: _isMovementMode,
                    movementOriginId: _movementOriginId,
                    movementTargetId: _movementTargetId,
                  ),
                  isComplex: true,
                  willChange: _isInteracting,
                ),
              ),
            ),
          ),
          
          if (selectedRegion != null && selectedProvince != null && selectedProvince.id.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showProvinceDetails && selectedProvince.owner == widget.game.playerNationTag)
                    Container(
                      transform: Matrix4.translationValues(0, -2, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (_movementTargetId != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      transform: Matrix4.translationValues(0, -2, 0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE57373),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0xFFC62828),
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
                                          onTap: () {
                                            setState(() {
                                              _movementTargetId = null;
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '❌',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      transform: Matrix4.translationValues(0, -2, 0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6EC53E),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0xFF4A9E1C),
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
                                          onTap: () {
                                            final originPath = _cachedPaths[selectedRegion!.id];
                                            final destPath = _cachedPaths[_movementTargetId!];
                                            if (originPath != null && destPath != null) {
                                              final daysRequired = calculateMovementDays(
                                                originPath.getBounds().center,
                                                destPath.getBounds().center,
                                              );
                                              _startMovementToProvince(_movementTargetId!, daysRequired);
                                            }
                                            setState(() {
                                              selectedRegion = null;
                                              _showProvinceDetails = false;
                                              _movementTargetId = null;
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '✓',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Move',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  if (_showProvinceDetails)
                    ProvinceDetailsPopup(
                      province: selectedProvince,
                      ownerNation: selectedNation,
                      game: widget.game,
                      onClose: () {
                        setState(() {
                          _showProvinceDetails = false;
                        });
                      },
                    ),
                  if (_showNationDetails && _selectedNation != null)
                    NationDetailsPopup(
                      nation: _selectedNation!,
                      playerNation: widget.game.playerNation,
                      game: widget.game,
                      onClose: () {
                        setState(() {
                          _showNationDetails = false;
                          _selectedNation = null;
                        });
                      },
                      onDeclareWar: _handleDeclareWar,
                      onMakePeace: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (context) => _ConfirmationDialog(
                            title: 'Make Peace',
                            message: 'Are you sure you want to make peace with ${_selectedNation!.name}?',
                            confirmText: 'Make Peace',
                            confirmColor: const Color(0xFF6EC53E),
                            confirmShadowColor: const Color(0xFF4A9E1C),
                            onConfirm: () {
                              final updatedGame = widget.game.makePeace(
                                widget.game.playerNationTag,
                                _selectedNation!.nationTag,
                              );
                              widget.onGameUpdate(updatedGame);
                              Navigator.of(context).pop();
                              setState(() {
                                _showNationDetails = false;
                                _selectedNation = null;
                              });
                            },
                            onCancel: () => Navigator.of(context).pop(),
                          ),
                        );
                      },
                      onFormAlliance: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (context) => _ConfirmationDialog(
                            title: 'Form Alliance',
                            message: 'Are you sure you want to form an alliance with ${_selectedNation!.name}?',
                            confirmText: 'Form Alliance',
                            confirmColor: const Color(0xFF67B9E7),
                            confirmShadowColor: const Color(0xFF4792BA),
                            onConfirm: () {
                              final updatedGame = widget.game.formAlliance(
                                widget.game.playerNationTag,
                                _selectedNation!.nationTag,
                              );
                              widget.onGameUpdate(updatedGame);
                              Navigator.of(context).pop();
                              setState(() {
                                _showNationDetails = false;
                                _selectedNation = null;
                              });
                            },
                            onCancel: () => Navigator.of(context).pop(),
                          ),
                        );
                      },
                      onBreakAlliance: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (context) => _ConfirmationDialog(
                            title: 'Break Alliance',
                            message: 'Are you sure you want to break your alliance with ${_selectedNation!.name}?',
                            confirmText: 'Break Alliance',
                            confirmColor: const Color(0xFFE57373),
                            confirmShadowColor: const Color(0xFFC62828),
                            onConfirm: () {
                              final updatedGame = widget.game.breakAlliance(
                                widget.game.playerNationTag,
                                _selectedNation!.nationTag,
                              );
                              widget.onGameUpdate(updatedGame);
                              Navigator.of(context).pop();
                              setState(() {
                                _showNationDetails = false;
                                _selectedNation = null;
                              });
                            },
                            onCancel: () => Navigator.of(context).pop(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (selectedRegion != null && _hasOutgoingMovement(selectedRegion!.id))
          Expanded(
            child: _buildCancelMovementButton(),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDetailsButton(),
        ),
        const SizedBox(width: 8),
        // Only show recruit button if we own the province
        if (selectedRegion != null) 
          Expanded(
            child: _buildRecruitButton(),
          ),
      ],
    );
  }

  Widget _buildCancelMovementButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      transform: Matrix4.translationValues(0, -2, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFE57373),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFC62828),
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
          onTap: () {
            _cancelMovementFromProvince(selectedRegion!.id);
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '❌',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      transform: Matrix4.translationValues(0, -2, 0),
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
          onTap: () {
            setState(() {
              _showProvinceDetails = true;
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecruitButton() {
    final province = _getProvinceForRegion(selectedRegion!.id);
    // Only show recruit button if we own the province
    if (province.owner != widget.game.playerNationTag) {
      return const SizedBox.shrink();
    }
    
    final playerNation = widget.game.playerNation;
    final canAfford = playerNation.gold >= 3000 && playerNation.armyReserve >= 30000;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      transform: Matrix4.translationValues(0, -2, 0),
      decoration: BoxDecoration(
        color: canAfford ? const Color(0xFF6EC53E) : Colors.grey,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: canAfford ? const Color(0xFF4A9E1C) : Colors.grey.shade600,
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
          onTap: canAfford ? _recruitArmy : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Recruit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _recruitArmy() {
    if (selectedRegion == null) return;
    
    final province = _getProvinceForRegion(selectedRegion!.id);
    final playerNation = widget.game.playerNation;
    
    // Check if we have enough resources
    if (playerNation.gold < 3000 || playerNation.armyReserve < 30000) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough resources: ${playerNation.gold < 3000 ? "Gold" : "Army reserves"} too low'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Create a new army in the province
    final updatedNations = widget.game.nations.map((nation) {
      if (nation.nationTag == widget.game.playerNationTag) {
        return nation.copyWith(
          gold: nation.gold - 3000,
          armyReserve: nation.armyReserve - 30000,
        );
      }
      return nation;
    }).toList();
    
    // Add the army to the province
    final updatedProvinces = widget.game.provinces.map((p) {
      if (p.id == selectedRegion!.id) {
        final newArmy = Army(
          id: 'army_${DateTime.now().millisecondsSinceEpoch}',
          nationTag: widget.game.playerNationTag,
          size: 30000,
        );
        return p.copyWith(
          armies: [...p.armies, newArmy],
        );
      }
      return p;
    }).toList();
    
    // Update the game
    final updatedGame = Game(
      id: widget.game.id,
      gameName: widget.game.gameName,
      date: widget.game.date,
      mapName: widget.game.mapName,
      playerNationTag: widget.game.playerNationTag,
      nations: updatedNations,
      provinces: updatedProvinces,
      battles: widget.game.battles,
    );
    
    widget.onGameUpdate(updatedGame);
    _triggerRepaint(); // Force a repaint to show the new army
  }

  void _handleGameUpdate(Game updatedGame) {
    // Check if there are any active battles
    final hasActiveBattle = updatedGame.battles.any((b) => b.isActive);
    
    widget.onGameUpdate(updatedGame);
    
    // Trigger repaint if there's an active battle
    if (hasActiveBattle) {
      _triggerRepaint();
    }
  }

  void _handleDeclareWar() {
    if (_selectedNation == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _ConfirmationDialog(
        title: 'Declare War',
        message: 'Are you sure you want to declare war on ${_selectedNation!.name}?',
        confirmText: 'Declare War',
        confirmColor: const Color(0xFFE57373),
        confirmShadowColor: const Color(0xFFC62828),
        onConfirm: () {
          final updatedGame = widget.game.declareWar(
            widget.game.playerNationTag,
            _selectedNation!.nationTag,
          );
          widget.onGameUpdate(updatedGame);
          Navigator.of(context).pop();
          setState(() {
            _showNationDetails = false;
            _selectedNation = null;
          });
          // Trigger repaint to update UI after war declaration
          _triggerRepaint();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final List<Region> regions;
  final Map<String, Path> cachedPaths;
  final Map<String, Color> cachedColors;
  final String? selectedRegionId;
  final Function(String?) onRegionSelected;
  final Game game;
  final double scale;
  final Map<String, ui.Image> flagImages;
  final bool isMovementMode;
  final String? movementOriginId;
  final String? movementTargetId;
  final Map<String, Rect> _cachedBounds = {};
  final Map<String, TextPainter> _cachedTextPainters = {};
  static const double MIN_TEXT_SCALE = 4.0;

  final List<({
    TextPainter painter,
    Offset offset,
    Rect bgRect,
    String nationTag,
    bool isSelected,
    Color bgColor,
  })> deferredText = [];

  MapPainter({
    required this.regions,
    required this.cachedPaths,
    required this.cachedColors,
    required this.selectedRegionId,
    required this.onRegionSelected,
    required this.game,
    required this.scale,
    required this.flagImages,
    required this.isMovementMode,
    required this.movementOriginId,
    required this.movementTargetId,
  }) {
    // Pre-calculate bounds for all paths
    for (final entry in cachedPaths.entries) {
      if (!_cachedBounds.containsKey(entry.key)) {
        _cachedBounds[entry.key] = entry.value.getBounds();
      }
    }
  }

  bool _canSeeArmyInProvince(Province province) {
    // Can always see armies in your own provinces
    if (province.owner == game.playerNationTag) {
      return true;
    }

    // Get the player's nation
    final playerNation = game.nations.firstWhere(
      (n) => n.nationTag == game.playerNationTag,
    );

    // Check if this province borders any of our provinces
    for (final playerProvinceId in playerNation.nationProvinces) {
      final playerProvince = game.provinces.firstWhere(
        (p) => p.id == playerProvinceId,
        orElse: () => Province(
          id: '',
          name: '',
          path: '',
          population: 0,
          goldIncome: 0,
          industry: 0,
          buildings: [],
          resourceType: ResourceType.none,
          armies: [],
          owner: '',
          borderingProvinces: [],
        ),
      );

      // Check if this province is in our bordering provinces
      if (playerProvince.borderingProvinces.contains(province.id)) {
        return true;
      }

      // Check if our province is in this province's bordering provinces
      if (province.borderingProvinces.contains(playerProvince.id)) {
        return true;
      }
    }

    return false;
  }

  int _getEffectiveArmySize(String provinceId) {
    final province = game.provinces.firstWhere(
      (p) => p.id == provinceId,
      orElse: () => Province(
        id: '',
        name: '',
        path: '',
        population: 0,
        goldIncome: 0,
        industry: 0,
        buildings: [],
        resourceType: ResourceType.none,
        armies: [],
        owner: '',
        borderingProvinces: [],
      ),
    );
    if (province.id.isEmpty) return 0;
    
    // Include armies that are in the process of moving
    for (final nation in game.nations) {
      final movement = nation.movements.firstWhere(
        (m) => m.originProvinceId == provinceId,
        orElse: () => Movement(
          originProvinceId: '',
          destinationProvinceId: '',
          daysLeft: 0,
          armySize: 0,
          nationTag: '',
        ),
      );
      if (movement.originProvinceId.isNotEmpty) {
        return movement.armySize;  // Show the moving army size
      }
    }
    return province.armies.fold<int>(0, (sum, army) => sum + army.size);  // Return actual army size if no movement
  }

  bool _canMoveToProvince(Province targetProvince) {
    if (selectedRegionId == null) return false;

    // Get the origin province
    final originProvince = game.provinces.firstWhere(
      (p) => p.id == selectedRegionId,
      orElse: () => Province(
        id: '',
        name: '',
        path: '',
        population: 0,
        goldIncome: 0,
        industry: 0,
        buildings: [],
        resourceType: ResourceType.none,
        armies: [],
        owner: '',
        borderingProvinces: [],
      ),
    );

    // Can only move to provinces that border the origin province
    if (!originProvince.borderingProvinces.contains(targetProvince.id)) {
      return false;
    }

    // Can move to own provinces or allied provinces
    if (targetProvince.owner == game.playerNationTag || 
        game.playerNation.allies.contains(targetProvince.owner)) {
      return true;
    }

    // Can move to enemy provinces if at war and we border them
    return game.playerNation.atWarWith.contains(targetProvince.owner);
  }

  bool _isHostileMovement(Province targetProvince) {
    return game.playerNation.atWarWith.contains(targetProvince.owner);
  }

  void _drawDeferredText(Canvas canvas) {
    for (final textItem in deferredText) {
      if (textItem.bgRect.isEmpty) continue;
      
      // Draw background rectangle with smaller radius
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          textItem.bgRect,
          Radius.circular(textItem.bgRect.height * 0.15),
        ),
        Paint()..color = textItem.bgColor,
      );

      // Draw flag on the left side with adjusted proportions
      final flagRect = Rect.fromLTWH(
        textItem.bgRect.left + textItem.bgRect.height * 0.08,
        textItem.bgRect.top + textItem.bgRect.height * 0.15,
        textItem.bgRect.height * 0.7,
        textItem.bgRect.height * 0.7,
      );

      // Draw flag image
      try {
        final flagImage = flagImages[textItem.nationTag];
        if (flagImage != null) {
          canvas.drawImageRect(
            flagImage,
            Rect.fromLTWH(0, 0, flagImage.width.toDouble(), flagImage.height.toDouble()),
            flagRect,
            Paint(),
          );
        }
      } catch (e) {
        print('Error drawing flag: $e');
      }

      // Draw text
      textItem.painter.paint(canvas, textItem.offset);
    }
  }

  void _drawDottedArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    if (start == end) return;
    
    // Calculate direction vector
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    
    // Normalize direction vector
    final dirX = dx / distance;
    final dirY = dy / distance;

    // Calculate where to stop the line (slightly before the end)
    final arrowSize = 0.8;  // Smaller arrow head
    final lineEndDistance = distance - arrowSize;
    
    // Draw solid or dotted line based on paint opacity
    if (paint.color.opacity > 0.5) {
      // Solid line for confirmed movements
      canvas.drawLine(start, Offset(
        start.dx + dirX * lineEndDistance,
        start.dy + dirY * lineEndDistance,
      ), paint);
    } else {
      // Dotted line for potential movements
      final dashLength = 0.2;  // Tiny dashes
      final gapLength = 0.2;   // Tiny gaps
      var currentDistance = 0.0;
      
      while (currentDistance < lineEndDistance) {
        final startPoint = Offset(
          start.dx + dirX * currentDistance,
          start.dy + dirY * currentDistance,
        );
        
        final endPoint = Offset(
          start.dx + dirX * min(currentDistance + dashLength, lineEndDistance),
          start.dy + dirY * min(currentDistance + dashLength, lineEndDistance),
        );
        
        canvas.drawLine(startPoint, endPoint, paint);
        currentDistance += dashLength + gapLength;
      }
    }

    // Draw tiny arrow at the end
    final perpX = -dirY;
    final perpY = dirX;
    
    final arrowTip = end;
    final arrowBase = Offset(
      end.dx - dirX * arrowSize,
      end.dy - dirY * arrowSize,
    );
    
    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(
        arrowBase.dx + perpX * arrowSize * 0.3,
        arrowBase.dy + perpY * arrowSize * 0.3,
      )
      ..lineTo(
        arrowBase.dx - perpX * arrowSize * 0.3,
        arrowBase.dy - perpY * arrowSize * 0.3,
      )
      ..close();
    
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Skip text rendering if zoom is too low
    final shouldRenderText = scale >= MIN_TEXT_SCALE;

    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.05
      ..style = PaintingStyle.stroke;

    deferredText.clear();

    // First pass: Draw all provinces
    for (final region in regions) {
      final path = cachedPaths[region.id];
      if (path == null) continue;
      
      final color = cachedColors[region.id];
      if (color == null) continue;
      
      // Check if the region is visible in the current viewport
      final bounds = _cachedBounds[region.id];
      if (bounds == null || !_isVisible(bounds, size)) continue;

      // Only highlight selected province if we own it
      final province = game.provinces.firstWhere(
        (p) => p.id == region.id,
        orElse: () => Province(
          id: '',
          name: '',
          path: '',
          population: 0,
          goldIncome: 0,
          industry: 0,
          buildings: [],
          resourceType: ResourceType.none,
          armies: [],
          owner: '',
          borderingProvinces: [],
        ),
      );

      final isOwnedSelected = selectedRegionId == region.id && province.owner == game.playerNationTag;
      
      if (isOwnedSelected) {
        // Draw highlight for selected owned province
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.blue.withOpacity(0.3)
            ..style = PaintingStyle.fill,
        );
      }
      
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawPath(path, borderPaint);

      if (shouldRenderText) {
        if (province.id.isEmpty) continue;
        
        final effectiveArmy = _getEffectiveArmySize(region.id);
        if (effectiveArmy > 0) {
          _addDeferredText(region.id, province, bounds, effectiveArmy);
        }
      }
    }

    // Draw movement arrows with optimized arrow drawing
    if (shouldRenderText) {
      _drawMovementArrows(canvas);
      _drawDeferredText(canvas);
    }

    // Draw flags for battles
    for (final textItem in deferredText) {
      if (textItem.nationTag.contains(',')) {
        // This is a battle, draw two flags
        final tags = textItem.nationTag.split(',');
        if (tags.length == 2) {
          // Draw attacker flag on the left
          final leftFlagRect = Rect.fromLTWH(
            textItem.bgRect.left + textItem.bgRect.height * 0.08,
            textItem.bgRect.top + textItem.bgRect.height * 0.15,
            textItem.bgRect.height * 0.7,
            textItem.bgRect.height * 0.7,
          );

          // Draw defender flag on the right
          final rightFlagRect = Rect.fromLTWH(
            textItem.bgRect.right - textItem.bgRect.height * 0.78,
            textItem.bgRect.top + textItem.bgRect.height * 0.15,
            textItem.bgRect.height * 0.7,
            textItem.bgRect.height * 0.7,
          );

          try {
            final attackerFlag = flagImages[tags[0]];
            final defenderFlag = flagImages[tags[1]];
            
            if (attackerFlag != null) {
              canvas.drawImageRect(
                attackerFlag,
                Rect.fromLTWH(0, 0, attackerFlag.width.toDouble(), attackerFlag.height.toDouble()),
                leftFlagRect,
                Paint(),
              );
            }
            
            if (defenderFlag != null) {
              canvas.drawImageRect(
                defenderFlag,
                Rect.fromLTWH(0, 0, defenderFlag.width.toDouble(), defenderFlag.height.toDouble()),
                rightFlagRect,
                Paint(),
              );
            }
          } catch (e) {
            print('Error drawing battle flags: $e');
          }
        }
      } else {
        // Regular army display, draw single flag
        try {
          final flagImage = flagImages[textItem.nationTag];
          if (flagImage != null) {
            final flagRect = Rect.fromLTWH(
              textItem.bgRect.left + textItem.bgRect.height * 0.08,
              textItem.bgRect.top + textItem.bgRect.height * 0.15,
              textItem.bgRect.height * 0.7,
              textItem.bgRect.height * 0.7,
            );
            
            canvas.drawImageRect(
              flagImage,
              Rect.fromLTWH(0, 0, flagImage.width.toDouble(), flagImage.height.toDouble()),
              flagRect,
              Paint(),
            );
          }
        } catch (e) {
          print('Error drawing flag: $e');
        }
      }
    }
  }

  bool _isVisible(Rect bounds, Size size) {
    // Simple viewport culling
    return bounds.overlaps(Offset.zero & size);
  }

  void _addDeferredText(String regionId, Province province, Rect bounds, int effectiveArmy) {
    if (province.owner.isEmpty) return;
    
    // Only show army count if we can see armies in this province
    if (!_canSeeArmyInProvince(province)) return;
    
    final ownerNation = game.nations.firstWhere(
      (n) => n.nationTag == province.owner,
      orElse: () => Nation(
        nationTag: '',
        name: '',
        color: '',
        hexColor: '',
        nationProvinces: [],
        allies: [],
        borderProvinces: [],
        gold: 0,
        researchPoints: 0,
        currentResearchId: null,
        currentResearchProgress: 0,
        buildQueue: null,
        isAI: false,
        armyReserve: 0,
      ),
    );

    if (ownerNation.nationTag.isEmpty) return;

    // Check if there's an active battle in this province
    final activeBattle = game.battles.firstWhere(
      (b) => b.provinceId == regionId && b.isActive == true,
      orElse: () => Battle(
        provinceId: '',
        attackerTag: '',
        defenderTag: '',
        attackerArmy: 0,
        defenderArmy: 0,
      ),
    );

    final isEnemy = game.playerNation.atWarWith.contains(province.owner);
    final textColor = isEnemy ? Colors.red : Colors.white;

    final center = bounds.center;
    double fontSize = (bounds.width.abs() * bounds.height.abs() * 0.0002).clamp(0.8, 1.4);

    if (activeBattle.provinceId.isNotEmpty) {
      // Show battle information
      final attackerNation = game.nations.firstWhere((n) => n.nationTag == activeBattle.attackerTag);
      final defenderNation = game.nations.firstWhere((n) => n.nationTag == activeBattle.defenderTag);

      final attackerArmyInK = activeBattle.attackerArmy / 1000.0;
      final defenderArmyInK = activeBattle.defenderArmy / 1000.0;
      
      final attackerNumber = attackerArmyInK < 1 
          ? attackerArmyInK.toStringAsFixed(1)
          : attackerArmyInK.floor().toString();
      final defenderNumber = defenderArmyInK < 1 
          ? defenderArmyInK.toStringAsFixed(1)
          : defenderArmyInK.floor().toString();

      final battleText = '$attackerNumber⚔️$defenderNumber';
      
      final textPainter = _cachedTextPainters[regionId] ?? TextPainter(
        text: TextSpan(
          text: battleText,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -fontSize * 0.05, // Reduced negative letter spacing
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      if (!_cachedTextPainters.containsKey(regionId)) {
        textPainter.layout(maxWidth: double.infinity);
        _cachedTextPainters[regionId] = textPainter;
      }

      final padding = fontSize * 0.25;
      final flagWidth = fontSize * 1.0;
      final totalWidth = textPainter.width + padding * 4 + flagWidth * 2; // Extra space for two flags
      final height = fontSize * 1.2;

      final bgRect = Rect.fromCenter(
        center: center,
        width: totalWidth,
        height: height,
      );

      if (bgRect.isEmpty) return;

      deferredText.add((
        painter: textPainter,
        offset: Offset(
          bgRect.left + flagWidth + padding,
          bgRect.top + (bgRect.height - textPainter.height) / 2 - (fontSize * 0.3),
        ),
        bgRect: bgRect,
        nationTag: '${attackerNation.nationTag.toLowerCase()},${defenderNation.nationTag.toLowerCase()}',
        isSelected: false,
        bgColor: Colors.black.withOpacity(0.8),
      ));
    } else {
      // Show normal army count
      final armyInK = effectiveArmy / 1000.0;
      final formattedNumber = armyInK < 1 
          ? armyInK.toStringAsFixed(1)
          : armyInK.floor().toString();

      final textPainter = _cachedTextPainters[regionId] ?? TextPainter(
        text: TextSpan(
          text: formattedNumber,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -fontSize * 0.14,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      if (!_cachedTextPainters.containsKey(regionId)) {
        textPainter.layout(maxWidth: double.infinity);
        _cachedTextPainters[regionId] = textPainter;
      }

      final padding = fontSize * 0.25;
      final flagWidth = fontSize * 1.0;
      final totalWidth = textPainter.width + padding * 3 + flagWidth;
      final height = fontSize * 1.2;

      final bgRect = Rect.fromCenter(
        center: center,
        width: totalWidth,
        height: height,
      );

      if (bgRect.isEmpty) return;

      final isHighlighted = regionId == selectedRegionId && province.owner == game.playerNationTag;
      final bgColor = isEnemy 
          ? Colors.black.withOpacity(0.6)
          : (isHighlighted ? Colors.blue.withOpacity(0.8) : Colors.black.withOpacity(0.6));

      deferredText.add((
        painter: textPainter,
        offset: Offset(
          bgRect.left + flagWidth + padding * 2,
          bgRect.top + (bgRect.height - textPainter.height) / 2 - (fontSize * 0.3),
        ),
        bgRect: bgRect,
        nationTag: province.owner.toLowerCase(),
        isSelected: isHighlighted,
        bgColor: bgColor,
      ));
    }
  }

  void _drawMovementArrows(Canvas canvas) {
    final friendlyMovementPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 0.15
      ..style = PaintingStyle.stroke;

    final friendlyPotentialMovementPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)  // Lower opacity for potential moves
      ..strokeWidth = 0.1  // Thinner line for potential moves
      ..style = PaintingStyle.stroke;

    final hostileMovementPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 0.15
      ..style = PaintingStyle.stroke;

    final hostilePotentialMovementPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)  // Lower opacity for potential moves
      ..strokeWidth = 0.1  // Thinner line for potential moves
      ..style = PaintingStyle.stroke;

    // Draw existing movements with solid lines
    for (final nation in game.nations) {
      final isPlayerNation = nation.nationTag == game.playerNationTag;
      final canSeeMovements = isPlayerNation || 
        game.playerNation.allies.contains(nation.nationTag) ||
        nation.borderProvinces.any((p) => game.playerNation.nationProvinces.contains(p));

      if (canSeeMovements) {
        for (final movement in nation.movements) {
          final targetProvince = game.provinces.firstWhere(
            (p) => p.id == movement.destinationProvinceId,
            orElse: () => Province(
              id: '',
              name: '',
              path: '',
              population: 0,
              goldIncome: 0,
              industry: 0,
              buildings: [],
              resourceType: ResourceType.none,
              armies: [],
              owner: '',
              borderingProvinces: [],
            ),
          );

          final isHostile = _isHostileMovement(targetProvince);
          _drawOptimizedArrow(
            canvas,
            movement.originProvinceId,
            movement.destinationProvinceId,
            isHostile ? hostileMovementPaint : friendlyMovementPaint,
          );
        }
      }
    }

    // Draw potential movement paths when a province is selected
    if (selectedRegionId != null) {
      final originProvince = game.provinces.firstWhere(
        (p) => p.id == selectedRegionId,
        orElse: () => Province(
          id: '',
          name: '',
          path: '',
          population: 0,
          goldIncome: 0,
          industry: 0,
          buildings: [],
          resourceType: ResourceType.none,
          armies: [],
          owner: '',
          borderingProvinces: [],
        ),
      );

      // Only show movement previews if we own the selected province
      if (originProvince.owner == game.playerNationTag) {
        // Draw light lines to all bordering provinces that we can move to
        for (final borderingId in originProvince.borderingProvinces) {
          final targetProvince = game.provinces.firstWhere(
            (p) => p.id == borderingId,
            orElse: () => Province(
              id: '',
              name: '',
              path: '',
              population: 0,
              goldIncome: 0,
              industry: 0,
              buildings: [],
              resourceType: ResourceType.none,
              armies: [],
              owner: '',
              borderingProvinces: [],
            ),
          );

          if (_canMoveToProvince(targetProvince)) {
            final isHostile = _isHostileMovement(targetProvince);
            if (movementTargetId == targetProvince.id) {
              // Draw solid line for selected target
              _drawOptimizedArrow(
                canvas,
                selectedRegionId!,
                targetProvince.id,
                isHostile ? hostileMovementPaint : friendlyMovementPaint,
              );
            } else {
              // Draw light line for potential target
              _drawOptimizedArrow(
                canvas,
                selectedRegionId!,
                targetProvince.id,
                isHostile ? hostilePotentialMovementPaint : friendlyPotentialMovementPaint,
              );
            }
          }
        }
      }
    }
  }

  void _drawOptimizedArrow(Canvas canvas, String fromId, String toId, Paint paint) {
    final originBounds = _cachedBounds[fromId];
    final destBounds = _cachedBounds[toId];
    
    if (originBounds != null && destBounds != null) {
      _drawDottedArrow(
        canvas,
        originBounds.center,
        destBounds.center,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.selectedRegionId != selectedRegionId ||
           oldDelegate.scale != scale ||
           oldDelegate.isMovementMode != isMovementMode ||
           oldDelegate.movementOriginId != movementOriginId ||
           oldDelegate.movementTargetId != movementTargetId;
  }

  @override
  bool hitTest(Offset position) {
    bool hitRegion = false;
    for (final region in regions) {
      final path = cachedPaths[region.id];
      if (path != null && path.contains(position)) {
        onRegionSelected(region.id);
        hitRegion = true;
        break;
      }
    }
    
    // If we didn't hit any region, clear the selection
    if (!hitRegion) {
      onRegionSelected(null);
    }
    return true;
  }

  Offset _getProvinceCenter(Province province) {
    final path = cachedPaths[province.id];
    if (path == null) return Offset.zero;
    final bounds = path.getBounds();
    return bounds.center;
  }
}

class Region {
  final String id;
  final String path;

  Region({required this.id, required this.path});
}

class RegionClipper extends CustomClipper<Path> {
  final String svgPath;

  RegionClipper({super.reclip, required this.svgPath});

  @override
  Path getClip(Size size) {
    final path = parseSvgPathData(svgPath);
    return path;
  }

  @override
  bool shouldReclip(RegionClipper oldClipper) {
    return false;
  }
}

class RegionBorderPainter extends CustomPainter {
  final Path path;
  late final Paint borderPaint;

  RegionBorderPainter({super.repaint, required this.path}) {
    borderPaint = Paint()
      ..color = const Color.fromARGB(255, 28, 28, 28)
      ..strokeWidth = 0.01
      ..style = PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path, borderPaint);
  }


  @override
  bool shouldRepaint(RegionBorderPainter oldDelegate) {
    return oldDelegate.path != path;
  }
}

class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;
  final Color confirmShadowColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.confirmColor,
    required this.confirmShadowColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  transform: Matrix4.translationValues(0, -2, 0),
                  decoration: BoxDecoration(
                    color: confirmColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: confirmShadowColor,
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
                      onTap: onConfirm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }
}