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
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'dart:math';


class InteractiveMap extends StatefulWidget {
  final Game game;
  final Function(Game) onGameUpdate;

  const InteractiveMap({
    super.key, 
    required this.game,
    required this.onGameUpdate,
  });

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> with SingleTickerProviderStateMixin {
  List<Region> regions = [];
  Region? selectedRegion;
  bool _isLoading = true;
  bool _showProvinceDetails = false;
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
        army: 0,
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    print('InteractiveMap initState');
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    // Set initial transformation to center the map
    transformationController.value = Matrix4.identity()
      ..scale(2.0)  // Initial zoom level
      ..translate(-100.0,);  // Center the map
    
    print('Starting to load regions...');
    loadRegions();
    _loadFlagImages();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cachedPaths.clear();
    _cachedColors.clear();
    super.dispose();
  }

  Future<void> loadRegions() async {
    print('loadRegions - beginning SVG parsing');
    const path = 'assets/svg/world_states_map.svg';
    final content = await rootBundle.loadString(path);
    print('SVG file loaded successfully');
    
    final document = XmlDocument.parse(content);
    final paths = document.findAllElements('path');
    print('Found ${paths.length} paths in SVG');
    
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
    
    print('Successfully parsed ${loadedRegions.length} regions');
    setState(() {
      regions = loadedRegions;
      _isLoading = false;
      print('State updated with ${regions.length} regions');
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

  void _handleRecruitArmy(String provinceId, int armyChange, int industryChange) {
    final updatedProvinces = widget.game.provinces.map((p) {
      if (p.id == provinceId) {
        return Province(
          id: p.id,
          name: p.name,
          path: p.path,
          population: p.population,
          goldIncome: p.goldIncome,
          industry: p.industry + industryChange,
          buildings: p.buildings,
          resourceType: p.resourceType,
          army: p.army + armyChange,
          owner: p.owner,
        );
      }
      return p;
    }).toList();

    final updatedGame = Game(
      id: widget.game.id,
      gameName: widget.game.gameName,
      date: widget.game.date,
      mapName: widget.game.mapName,
      playerNationTag: widget.game.playerNationTag,
      nations: widget.game.nations,
      provinces: updatedProvinces,
    );

    widget.onGameUpdate(updatedGame);
  }

  void _startMovement() {
    if (selectedRegion == null) return;
    
    final province = _getProvinceForRegion(selectedRegion!.id);
    if (!_canSelectProvince(province)) return;
    
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
        ),
      );
      if (movement.originProvinceId.isNotEmpty) {
        final destProvince = widget.game.provinces.firstWhere((p) => p.id == movement.destinationProvinceId);
        return 'Moving to ${destProvince.name} in ${movement.daysLeft} days';
      }
    }
    return null;
  }

  int _getEffectiveArmySize(String provinceId) {
    final province = _getProvinceForRegion(provinceId);
    
    // Include armies that are in the process of moving
    for (final nation in widget.game.nations) {
      final movement = nation.movements.firstWhere(
        (m) => m.originProvinceId == provinceId,
        orElse: () => Movement(
          originProvinceId: '',
          destinationProvinceId: '',
          daysLeft: 0,
          armySize: 0,
        ),
      );
      if (movement.originProvinceId.isNotEmpty) {
        return movement.armySize;  // Show the moving army size
      }
    }
    return province.army;  // Return actual army size if no movement
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
    // Use a multiplier of 5 days per unit of distance
    return max(1, (distance * 5).round());
  }

  bool _canSelectProvince(Province province) {
    return province.owner == widget.game.playerNationTag;
  }

  bool _canMoveToProvince(Province targetProvince) {
    if (targetProvince.owner == widget.game.playerNationTag) {
      return true;  // Can always move to own provinces
    }
    
    // Check if the owner is an ally
    final playerNation = widget.game.nations.firstWhere(
      (n) => n.nationTag == widget.game.playerNationTag,
    );
    
    return playerNation.allies.contains(targetProvince.owner);
  }

  void _handleRegionTap(String? regionId) {
    if (regionId == null) {
      setState(() {
        selectedRegion = null;
        _showProvinceDetails = false;
        _movementTargetId = null;
      });
      return;
    }

    final targetProvince = _getProvinceForRegion(regionId);
    
    setState(() {
      if (selectedRegion != null && regionId != selectedRegion!.id) {
        final originProvince = _getProvinceForRegion(selectedRegion!.id);
        if (originProvince.army > 0 && _canSelectProvince(originProvince) && _canMoveToProvince(targetProvince)) {
          // If this is a new target, set it as movement target
          if (_movementTargetId != regionId) {
            _movementTargetId = regionId;
            return;
          }
        }
      }

      // If we're clicking the target province again, confirm movement
      if (_movementTargetId == regionId) {
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

      // Normal province selection
      if (_canSelectProvince(targetProvince)) {
        selectedRegion = Region(id: regionId, path: '');
        _showProvinceDetails = false;
        _movementTargetId = null;
      }
    });
  }

  void _startMovementToProvince(String destinationId, int daysRequired) {
    if (selectedRegion == null) return;
    
    final originProvince = _getProvinceForRegion(selectedRegion!.id);
    if (originProvince.army <= 0) return;

    final updatedNations = widget.game.nations.map((nation) {
      if (nation.nationTag == widget.game.playerNationTag) {
        return nation.copyWith(
          movements: [
            ...nation.movements,
            Movement(
              originProvinceId: selectedRegion!.id,
              destinationProvinceId: destinationId,
              daysLeft: daysRequired,
              armySize: originProvince.army,
            ),
          ],
        );
      }
      return nation;
    }).toList();

    final updatedProvinces = widget.game.provinces.map((p) {
      if (p.id == selectedRegion!.id) {
        return Province(
          id: p.id,
          name: p.name,
          path: p.path,
          population: p.population,
          goldIncome: p.goldIncome,
          industry: p.industry,
          buildings: p.buildings,
          resourceType: p.resourceType,
          army: 0,
          owner: p.owner,
        );
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
    );

    widget.onGameUpdate(updatedGame);
    setState(() {
      _isMovementMode = false;
      selectedRegion = null;
    });
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
          Center(
            child: InteractiveViewer(
              transformationController: transformationController,
              boundaryMargin: const EdgeInsets.all(8.0),
              minScale: 1.0,  // Prevent zooming out too far
              maxScale: 20.0,
              constrained: false,
              onInteractionUpdate: (details) {
                setState(() {});
              },
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
                  ),
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
                  if (!_showProvinceDetails)
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
                                        color: const Color(0xFFE57373), // Light red
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0xFFC62828), // Darker red
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
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Move to ${_getProvinceForRegion(_movementTargetId!).name}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      transform: Matrix4.translationValues(0, -2, 0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6EC53E), // Light green
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0xFF4A9E1C), // Darker green
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
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 24,
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
                                    color: const Color(0xFFFFA726), // Light orange
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFFF57C00), // Darker orange
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
                                        // Add recruit functionality
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
                                    color: const Color(0xFF67B9E7), // Light blue
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF4792BA), // Darker blue
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
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (_showProvinceDetails)
                    ProvinceDetailsPopup(
                      province: selectedProvince,
                      ownerNation: selectedNation,
                      onRecruitArmy: selectedProvince.army >= 10 
                        ? (armyChange, industryChange) => _handleRecruitArmy(
                            selectedProvince.id,
                            armyChange,
                            industryChange,
                          )
                        : null,
                      onClose: () {
                        setState(() {
                          _showProvinceDetails = false;
                        });
                      },
                    ),
                ],
              ),
            ),
        ],
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

  final List<({
    TextPainter painter,
    Offset offset,
    Rect bgRect,
    String nationTag,
    bool isSelected,
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
  });

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
        army: 0,
        owner: '',
      ),
    );
    
    // Include armies that are in the process of moving
    for (final nation in game.nations) {
      final movement = nation.movements.firstWhere(
        (m) => m.originProvinceId == provinceId,
        orElse: () => Movement(
          originProvinceId: '',
          destinationProvinceId: '',
          daysLeft: 0,
          armySize: 0,
        ),
      );
      if (movement.originProvinceId.isNotEmpty) {
        return movement.armySize;  // Show the moving army size
      }
    }
    return province.army;  // Return actual army size if no movement
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Skip text rendering if zoom is too low
    final shouldRenderText = scale >= 4.0;

    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.05
      ..style = PaintingStyle.stroke;

    deferredText.clear();

    // First pass: Draw all provinces
    for (final region in regions) {
      final path = cachedPaths[region.id]!;
      final color = cachedColors[region.id]!;
      
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawPath(path, borderPaint);

      if (shouldRenderText) {
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
            army: 0,
            owner: '',
          ),
        );

        final effectiveArmy = _getEffectiveArmySize(region.id);
        
        if (effectiveArmy > 0) {
          // Get the owning nation of this province
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
            ),
          );

          // Get the player's nation
          final playerNation = game.nations.firstWhere(
            (n) => n.nationTag == game.playerNationTag,
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
            ),
          );

          // Only show armies if:
          // 1. Province is owned by an ally (including player's own nation)
          // 2. OR Province is in player's border provinces
          final isAllied = ownerNation.nationTag == playerNation.nationTag || 
                         playerNation.allies.contains(ownerNation.nationTag);
          final isBorderProvince = playerNation.borderProvinces.contains(province.id) || ownerNation.borderProvinces.contains(province.id);
          
          if (isAllied || isBorderProvince) {
            final bounds = path.getBounds();
            final center = bounds.center;
            
            // Format army number divided by 1000
            final armyInK = effectiveArmy / 1000.0;
            String formattedNumber;
            
            if (armyInK < 1) {
                formattedNumber = armyInK.toStringAsFixed(1);
            } else {
                formattedNumber = armyInK.floor().toString();
            }
            
            final provinceSize = bounds.width.abs() * bounds.height.abs();
            final fontSize = (provinceSize * 0.0002).clamp(0.8, 1.4);
            
            final textSpan = TextSpan(
              text: formattedNumber,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: -fontSize * 0.05,
              ),
            );
            
            final provincePainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            );
            
            provincePainter.layout(maxWidth: double.infinity);
            final requiredWidth = provincePainter.width;
            
            // Calculate rectangle dimensions with smaller proportions
            final padding = fontSize * 0.25;
            final flagWidth = fontSize * 1.0;
            final totalWidth = requiredWidth + padding * 3 + flagWidth;
            final height = fontSize * 1.2;

            final bgRect = Rect.fromCenter(
              center: center,
              width: totalWidth,
              height: height,
            );
            
            deferredText.add((
              painter: provincePainter,
              offset: Offset(
                bgRect.left + flagWidth + padding * 2,
                bgRect.top + (bgRect.height - provincePainter.height) / 2 - (fontSize * 0.3),
              ),
              bgRect: bgRect,
              nationTag: province.owner.toLowerCase(),
              isSelected: region.id == selectedRegionId,
            ));
          }
        }
      }
    }

    // Draw movement arrows
    final movementPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 0.15
      ..style = PaintingStyle.stroke;

    // Draw existing movements
    for (final nation in game.nations) {
      final isPlayerNation = nation.nationTag == game.playerNationTag;
      final canSeeMovements = isPlayerNation || 
        game.playerNation.allies.contains(nation.nationTag) ||
        nation.borderProvinces.any((p) => game.playerNation.nationProvinces.contains(p));

      if (canSeeMovements) {
        for (final movement in nation.movements) {
          final originPath = cachedPaths[movement.originProvinceId];
          final destPath = cachedPaths[movement.destinationProvinceId];
          
          if (originPath != null && destPath != null) {
            final originBounds = originPath.getBounds();
            final destBounds = destPath.getBounds();
            
            _drawDottedArrow(
              canvas,
              originBounds.center,
              destBounds.center,
              movementPaint,
            );
          }
        }
      }
    }

    // Draw movement preview if in movement mode
    if (isMovementMode && movementOriginId != null) {
      final originPath = cachedPaths[movementOriginId];
      if (originPath != null) {
        final originBounds = originPath.getBounds();
        
        // Draw preview to mouse position or selected province
        if (selectedRegionId != null && selectedRegionId != movementOriginId) {
          final destPath = cachedPaths[selectedRegionId];
          if (destPath != null) {
            final destBounds = destPath.getBounds();
            _drawDottedArrow(
              canvas,
              originBounds.center,
              destBounds.center,
              movementPaint,
            );
          }
        }
      }
    }

    // Draw army displays last
    if (shouldRenderText) {
      for (final textItem in deferredText) {
        // Draw background rectangle with smaller radius
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            textItem.bgRect,
            Radius.circular(textItem.bgRect.height * 0.15),
          ),
          Paint()..color = textItem.isSelected 
            ? Colors.blue.withOpacity(0.8) 
            : Colors.black.withOpacity(0.6),
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
  }

  void _drawDottedArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
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
    
    // Draw dotted line
    final dashLength = 0.2;  // Tiny dashes
    final gapLength = 0.2;   // Tiny gaps
    var currentDistance = 0.0;
    
    paint.strokeWidth = 0.15;  // Even thinner line
    
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
        arrowBase.dx + perpX * arrowSize * 0.3,  // Reduced from 0.5 to 0.3 for thinner arrow head
        arrowBase.dy + perpY * arrowSize * 0.3,
      )
      ..lineTo(
        arrowBase.dx - perpX * arrowSize * 0.3,  // Reduced from 0.5 to 0.3 for thinner arrow head
        arrowBase.dy - perpY * arrowSize * 0.3,
      )
      ..close();
    
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.selectedRegionId != selectedRegionId ||
           oldDelegate.game != game ||
           oldDelegate.scale != scale;
  }

  @override
  bool hitTest(Offset position) {
    bool hitRegion = false;
    for (final region in regions) {
      final path = cachedPaths[region.id]!;
      if (path.contains(position)) {
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
      ..color = Colors.black
      ..strokeWidth = 0.02
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