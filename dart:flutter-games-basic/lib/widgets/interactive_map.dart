import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:game_app/models/game.dart';
import 'package:game_app/models/region.dart';
import 'package:game_app/utils/utils.dart';

class InteractiveMap extends StatefulWidget {
  final Game game;
  final Function(Game) onGameUpdate;

  const InteractiveMap({Key? key, required this.game, required this.onGameUpdate}) : super(key: key);

  @override
  _InteractiveMapState createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  late Game game;
  late List<Region> regions;
  late Map<String, Path> cachedPaths;
  late List<Color> _cachedColors;
  late bool isMovementMode;
  late String? movementOriginId;
  late String? selectedRegionId;
  late Region? selectedRegion;
  late Province? selectedProvince;
  late bool _showProvinceDetails;
  late String? _movementTargetId;

  @override
  void initState() {
    super.initState();
    game = widget.game;
    regions = game.provinces.map((p) => Region(id: p.id, path: '')).toList();
    cachedPaths = {};
    _cachedColors = [];
    isMovementMode = false;
    movementOriginId = null;
    selectedRegionId = null;
    selectedRegion = null;
    selectedProvince = null;
    _showProvinceDetails = false;
    _movementTargetId = null;
  }

  void _handleRecruitArmy(String provinceId) {
    try {
      final province = _getProvinceForRegion(provinceId);
      if (province.id.isEmpty) {
        print('Province not found: $provinceId');
        return;
      }

      final playerNation = widget.game.nations.firstWhere(
        (n) => n.nationTag == widget.game.playerNationTag,
        orElse: () => throw Exception('Player nation not found'),
      );

      // Calculate total industry and population
      final totalIndustry = playerNation.getTotalIndustry(widget.game.provinces);
      final minGoldAllowed = -(totalIndustry * 150);
      final recruitCost = 3000;

      // Check if we have enough gold or can go into allowed debt
      if (playerNation.gold - recruitCost < minGoldAllowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough gold and exceeds allowed debt limit'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check if we have enough reserve soldiers
      if (playerNation.armyReserve < 30000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough soldiers in reserve (need 30,000)'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Update the game state
      final updatedProvinces = widget.game.provinces.map((p) {
        if (p.id == provinceId) {
          return p.copyWith(
            army: p.army + 30000,
          );
        }
        return p;
      }).toList();

      final updatedNations = widget.game.nations.map((n) {
        if (n.nationTag == widget.game.playerNationTag) {
          return n.copyWith(
            gold: n.gold - recruitCost,
            armyReserve: n.armyReserve - 30000,
          );
        }
        return n;
      }).toList();

      final updatedGame = Game(
        id: widget.game.id,
        gameName: widget.game.gameName,
        date: widget.game.date,
        mapName: widget.game.mapName,
        playerNationTag: widget.game.playerNationTag,
        nations: updatedNations,
        provinces: updatedProvinces,
      );

      // Update the game state and persist changes
      widget.onGameUpdate(updatedGame);

      // Force a rebuild of the map to show updated army numbers
      setState(() {
        _cachedColors.clear(); // Clear cached colors to ensure proper refresh
        selectedRegion = null; // Deselect the province to force re-render
        _showProvinceDetails = false;
      });
    } catch (e) {
      print('Error in _handleRecruitArmy: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recruiting army: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleMovementCompletion() {
    final now = widget.game.date;
    final updatedNations = widget.game.nations.map((nation) {
      final completedMovements = nation.movements.where((m) {
        final originProvince = _getProvinceForRegion(m.originProvinceId);
        final destProvince = _getProvinceForRegion(m.destinationProvinceId);
        return m.daysLeft <= 0 && originProvince.id.isNotEmpty && destProvince.id.isNotEmpty;
      }).toList();

      if (completedMovements.isEmpty) {
        return nation;
      }

      // Update provinces with completed movements
      final updatedProvinces = widget.game.provinces.map((p) {
        final completedMovement = completedMovements.firstWhere(
          (m) => m.destinationProvinceId == p.id,
          orElse: () => Movement(
            originProvinceId: '',
            destinationProvinceId: '',
            daysLeft: 0,
            armySize: 0,
          ),
        );

        if (completedMovement.destinationProvinceId.isNotEmpty) {
          return p.copyWith(
            army: p.army + completedMovement.armySize,
          );
        }
        return p;
      }).toList();

      // Remove completed movements
      final remainingMovements = nation.movements.where((m) => m.daysLeft > 0).toList();

      return nation.copyWith(
        movements: remainingMovements,
      );
    }).toList();

    final updatedGame = Game(
      id: widget.game.id,
      gameName: widget.game.gameName,
      date: now,
      mapName: widget.game.mapName,
      playerNationTag: widget.game.playerNationTag,
      nations: updatedNations,
      provinces: widget.game.provinces,
    );

    widget.onGameUpdate(updatedGame);

    // Select and deselect each completed movement's destination to force re-render
    for (final nation in updatedNations) {
      for (final movement in nation.movements) {
        if (movement.daysLeft <= 0) {
          setState(() {
            selectedRegion = Region(id: movement.destinationProvinceId, path: '');
          });
          Future.delayed(Duration.zero, () {
            if (mounted) {
              setState(() {
                selectedRegion = null;
              });
            }
          });
        }
      }
    }
  }

  void _forceRerender() {
    setState(() {
      _cachedColors.clear();
      _cachedPaths.clear();
      _cachedBounds.clear();
      _cachedTextPainters.clear();
      _cachedVisibility.clear();
    });
  }

  @override
  void didUpdateWidget(InteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game.date != oldWidget.game.date) {
      _handleMovementCompletion();
    }
  }

  void _drawMovementArrows(Canvas canvas) {
    // Draw existing movements with solid white arrows
    for (final nation in game.nations) {
      final isPlayerNation = nation.nationTag == game.playerNationTag;
      final canSeeMovements = isPlayerNation || 
        game.playerNation.allies.contains(nation.nationTag) ||
        nation.borderProvinces.any((p) => game.playerNation.nationProvinces.contains(p));

      if (canSeeMovements) {
        for (final movement in nation.movements) {
          _drawOptimizedArrow(
            canvas,
            movement.originProvinceId,
            movement.destinationProvinceId,
            Paint()
              ..color = Colors.white.withOpacity(0.9)
              ..strokeWidth = 0.15
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }

    // Draw movement preview with light gray arrows
    if (isMovementMode && movementOriginId != null && selectedRegionId != null && selectedRegionId != movementOriginId) {
      _drawOptimizedArrow(
        canvas,
        movementOriginId!,
        selectedRegionId!,
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..strokeWidth = 0.15
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing code ...
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            transform: Matrix4.translationValues(0, -2, 0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA726),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFF57C00),
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
                                  _handleRecruitArmy(selectedRegion!.id);
                                },
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
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
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
                                  _forceRerender();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Refresh',
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
                  ],
                ),
              ),
            // ... rest of the existing code ...
          ],
        ),
      ),
    // ... rest of the existing code ...
  }
} 