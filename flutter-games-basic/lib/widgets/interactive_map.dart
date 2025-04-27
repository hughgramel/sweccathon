// This widget displays the map of the world in SVG format 
// It takes a game object and adjusts its map using the data
// It then displays the map data in an SVG format
// It also displays the player's nation on the map

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_types.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';


class InteractiveMap extends StatefulWidget {
  final Game game;

  const InteractiveMap({super.key, required this.game});

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> with SingleTickerProviderStateMixin {
  List<Region> regions = [];
  Region? selectedRegion;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print('InteractiveMap initState');
    
    // Initialize fade controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    print('Starting to load regions...');
    loadRegions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
    }
    
    print('Successfully parsed ${loadedRegions.length} regions');
    setState(() {
      regions = loadedRegions;
      _isLoading = false;
      print('State updated with ${regions.length} regions');
    });
    _fadeController.forward();
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: InteractiveViewer(
          boundaryMargin: EdgeInsets.all(8.0),
          minScale: 0.1,
          maxScale: 20.0,
          constrained: false,
          child: Column(
            children: [
              // Large box to be above the map
              Container(
                width: 1200,
                height: 200,
                color: const Color.fromARGB(255, 209, 229, 240),
              ),
              SizedBox(
                width: 1200,
                height: 480,
                child: Container(
                  color: const Color.fromARGB(255, 209, 229, 240),
                  child: Stack(
                    children: [
                      for (final region in regions)...{
                        _getRegionImage(region, selectedRegion == region ? Colors.green : Colors.grey),
                        _getRegionBorder(region),
                      }
                    ],
                  ),
                ),
              ),
              Container(
                width: 1200,
                height: 200,
                color: const Color.fromARGB(255, 209, 229, 240),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getRegionImage(Region region, [Color? color = Colors.grey]) {
    return ClipPath(
      clipper: RegionClipper(svgPath: region.path),
      child: GestureDetector(
        onTap: () {
          print('Tapped on region ${region.id}');
          setState(() {
            selectedRegion = region;
          });
        },
        child: Container(
          color: color,
        ),
      ),
    );
  }
}

Widget _getRegionBorder(Region region) {
  return CustomPaint(
    painter: RegionBorderPainter(path: parseSvgPathData(region.path)),
  );
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