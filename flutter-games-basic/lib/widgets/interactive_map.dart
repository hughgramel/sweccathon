import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/game_types.dart';
import '../services/map_service.dart';
import 'map_painter.dart';

class InteractiveMap extends StatefulWidget {
  final Nation nation;

  const InteractiveMap({
    super.key,
    required this.nation,
  });

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final MapService _mapService = MapService();
  final GlobalKey _mapKey = GlobalKey();
  
  Map<String, Path> provincePaths = {};
  Province? selectedProvince;
  bool _isLoading = true;
  String? _errorMessage;
  Offset? _lastTapPosition;
  
  // Map of province IDs to their paths
  final Map<String, Province> _provinceMap = {};
  
  @override
  void initState() {
    super.initState();
    _loadMap();
    _provinceMap.addAll({
      for (var province in widget.nation.provinces)
        province.id: province,
    });
  }

  Future<void> _loadMap() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final paths = await _mapService.loadProvincePaths();
      setState(() {
        provincePaths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading map: $e';
        _isLoading = false;
      });
    }
  }

  void _handleTap(Offset localPosition) {
    setState(() {
      _lastTapPosition = localPosition;
    });

    if (provincePaths.isEmpty) return;

    final RenderBox? renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final mapPainter = (renderBox as dynamic).painter as MapPainter;
    final provinceId = mapPainter.getProvinceAtPoint(localPosition);
    
    if (provinceId != null) {
      setState(() {
        selectedProvince = _provinceMap[provinceId];
      });
      // Show a snackbar with the province name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Province selected: ${selectedProvince?.name ?? "Unknown"}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (selectedProvince != null) {
      setState(() {
        selectedProvince = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMap,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // The InteractiveViewer handles zoom and pan
        InteractiveViewer(
          minScale: 0.3,
          maxScale: 35.0,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          scaleEnabled: true,
          child: GestureDetector(
            onTapDown: (details) {
              _handleTap(details.localPosition);
            },
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red,
                    width: 2.0,
                  ),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 3,
                  height: MediaQuery.of(context).size.height * 3,
                  child: CustomPaint(
                    key: _mapKey,
                    painter: MapPainter(
                      nation: widget.nation,
                      selectedProvince: selectedProvince,
                      provincePaths: provincePaths,
                      canvasSize: Size(
                        MediaQuery.of(context).size.width * 3,
                        MediaQuery.of(context).size.height * 3,
                      ),
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Debug information
        if (_lastTapPosition != null)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tap position: (${_lastTapPosition!.dx.toStringAsFixed(1)}, ${_lastTapPosition!.dy.toStringAsFixed(1)})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
} 