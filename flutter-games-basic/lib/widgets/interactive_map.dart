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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Cache for parsed paths and colors
  final Map<String, Path> _pathCache = {};
  final Map<String, Color> _colorCache = {};
  final Map<String, Widget> _regionCache = {};
  
  // Cache for province and nation lookups
  final Map<String, Province> _provinceCache = {};
  final Map<String, Nation> _nationCache = {};

  @override
  void initState() {
    super.initState();
    print('InteractiveMap initState');
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    loadRegions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pathCache.clear();
    _colorCache.clear();
    _regionCache.clear();
    _provinceCache.clear();
    _nationCache.clear();
    super.dispose();
  }

  // Optimized province lookup with caching
  Province _getProvinceForRegion(String regionId) {
    return _provinceCache.putIfAbsent(regionId, () {
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
    });
  }

  // Optimized nation lookup with caching
  Nation? _getNationForProvince(Province province) {
    if (province.owner.isEmpty) return null;
    return _nationCache.putIfAbsent(province.owner, () {
      return widget.game.nations.firstWhere(
        (n) => n.nationTag == province.owner,
        orElse: () => Nation(
          nationTag: '',
          name: '',
          color: '',
          hexColor: '',
          nationProvinces: [],
          gold: 0,
          researchPoints: 0,
          currentResearchProgress: 0,
          isAI: false,
        ),
      );
    });
  }

  // Optimized color conversion with caching
  Color _hexToColor(String hexString) {
    return _colorCache.putIfAbsent(hexString, () {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    });
  }

  // Optimized path parsing with caching
  Path _parsePath(String svgPath) {
    return _pathCache.putIfAbsent(svgPath, () => parseSvgPathData(svgPath));
  }

  // Optimized province color lookup with caching
  Color _getProvinceColor(String regionId) {
    final province = _getProvinceForRegion(regionId);
    if (province.id.isEmpty) {
      return Colors.grey;
    }

    final ownerNation = _getNationForProvince(province);
    if (ownerNation == null) {
      return Colors.grey;
    }

    return _hexToColor(ownerNation.hexColor);
  }

  // Optimized region widget creation with caching
  Widget _getRegionWidget(Region region) {
    return _regionCache.putIfAbsent(region.id, () {
      final path = _parsePath(region.path);
      final color = _getProvinceColor(region.id);
      
      return RepaintBoundary(
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedRegion = region;
            });
          },
          child: CustomPaint(
            painter: RegionPainter(
              path: path,
              color: color,
            ),
          ),
        ),
      );
    });
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
    }
    
    print('Successfully parsed ${loadedRegions.length} regions');
    setState(() {
      regions = loadedRegions;
      _isLoading = false;
      print('State updated with ${regions.length} regions');
    });
    _fadeController.forward();
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
              boundaryMargin: const EdgeInsets.all(8.0),
              minScale: 0.1,
              maxScale: 20.0,
              constrained: false,
              child: RepaintBoundary(
                child: Container(
                  width: 1200,
                  height: 880,
                  color: const Color.fromARGB(255, 209, 229, 240),
                  child: Stack(
                    children: [
                      ...regions.map((region) => _getRegionWidget(region)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (selectedProvince != null && selectedProvince.id.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ProvinceDetailsPopup(
                province: selectedProvince,
                ownerNation: selectedNation,
                onRecruitArmy: selectedProvince.industry >= 10 
                  ? (armyChange, industryChange) => _handleRecruitArmy(
                      selectedProvince.id,
                      armyChange,
                      industryChange,
                    )
                  : null,
              ),
            ),
        ],
      ),
    );
  }
}

// Optimized painter that combines color and border
class RegionPainter extends CustomPainter {
  final Path path;
  final Color color;
  final Paint fillPaint;
  final Paint borderPaint;

  RegionPainter({
    required this.path,
    required this.color,
  }) : fillPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        borderPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 0.05
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(RegionPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.color != color;
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
      ..strokeWidth = 0.05
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