import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../models/game_types.dart';
import '../services/map_service.dart';
import 'dart:ui' as ui;

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
  final TransformationController _transformationController = TransformationController();
  
  Map<String, Path> provincePaths = {};
  Province? selectedProvince;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Zoom constraints
  final double _minScale = 0.3;
  final double _maxScale = 35.0;
  
  // Double tap zoom
  final double _doubleTapZoomFactor = 2.0;
  
  @override
  void initState() {
    super.initState();
    _loadMap();
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
          transformationController: _transformationController,
          minScale: _minScale,
          maxScale: _maxScale,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          onInteractionEnd: (details) {
            // Add custom behavior after interactions if needed
          },
          // Enable constrained and scalable interactions
          constrained: false,
          scaleEnabled: true,
          // Add double tap to zoom behavior
          child: GestureDetector(
            onDoubleTap: () {
              _zoom(_doubleTapZoomFactor);
            },
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 3, // Make the canvas larger for more zoom space
                height: MediaQuery.of(context).size.height * 3,
                child: CustomPaint(
                  painter: MapPainter(
                    nation: widget.nation,
                    selectedProvince: selectedProvince,
                    provincePaths: provincePaths,
                  ),
                  // Make the entire canvas tappable
                  child: ColoredBox(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
        
        // Zoom buttons
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                onPressed: () => _zoomIn(),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                onPressed: () => _zoomOut(),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _zoomIn() {
    _zoom(2.0); // Scale up by 100% (double)
  }

  void _zoomOut() {
    _zoom(0.5); // Scale down by 50% (half)
  }

  void _zoom(double scaleFactor) {
    // Get the current scale
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    
    // Calculate new scale, respecting min/max constraints
    final newScale = (currentScale * scaleFactor).clamp(_minScale, _maxScale);
    
    // Calculate scaling factor from current to new scale
    final effectiveScaleFactor = newScale / currentScale;
    
    // Get the center of the screen
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Clone current matrix to avoid direct modification
    final Matrix4 matrix = Matrix4.copy(_transformationController.value);
    
    // Apply zoom transformation centered on the screen center
    final translation = matrix.getTranslation();
    final translationVector = Vector3(translation.x, translation.y, 0);
    
    // Calculate center point in the original coordinate space
    final centerPoint = Vector3(
      centerX - translationVector.x, 
      centerY - translationVector.y,
      0,
    ) / currentScale;
    
    // Create new matrix with the zoom centered on the screen center
    final newMatrix = Matrix4.identity()
      ..translate(centerX - centerPoint.x * newScale, centerY - centerPoint.y * newScale)
      ..scale(newScale);
    
    // Apply the new transformation
    _transformationController.value = newMatrix;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

class MapPainter extends CustomPainter {
  final Nation nation;
  final Province? selectedProvince;
  final Map<String, Path> provincePaths;

  MapPainter({
    required this.nation,
    required this.selectedProvince,
    required this.provincePaths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (provincePaths.isEmpty) return;

    // Calculate bounds of all paths
    Rect fullBounds = provincePaths.values.first.getBounds();
    for (final path in provincePaths.values.skip(1)) {
      fullBounds = fullBounds.expandToInclude(path.getBounds());
    }

    // Calculate scale to fit the paths within the canvas
    final scaleX = size.width / fullBounds.width;
    final scaleY = size.height / fullBounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Scale factor to leave margins
    final scaleFactor = scale * 0.8;

    canvas.save();
    
    // Center the map on the canvas
    final dx = (size.width - (fullBounds.width * scaleFactor)) / 2 - fullBounds.left * scaleFactor;
    final dy = (size.height - (fullBounds.height * scaleFactor)) / 2 - fullBounds.top * scaleFactor;
    
    canvas.translate(dx, dy);
    canvas.scale(scaleFactor);

    // Draw background
    final backgroundPaint = Paint()
      ..color = const Color(0xFFADD8E6) // Light blue for water
      ..style = PaintingStyle.fill;
    
    // Draw background with padding
    canvas.drawRect(
      fullBounds.inflate(fullBounds.width * 0.1), 
      backgroundPaint
    );

    // Draw provinces
    final provincePaint = Paint()
      ..color = const Color(0xFFE8E8E8) // Light grey for land
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.01;

    for (final path in provincePaths.values) {
      canvas.drawPath(path, provincePaint);
      canvas.drawPath(path, borderPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.nation != nation ||
           oldDelegate.selectedProvince != selectedProvince ||
           oldDelegate.provincePaths != provincePaths;
  }
} 