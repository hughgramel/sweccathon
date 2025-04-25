import 'package:flutter/material.dart';
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

class _InteractiveMapState extends State<InteractiveMap> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  Matrix4? _initialMatrix;
  final MapService _mapService = MapService();
  
  // Store selected province
  Province? selectedProvince;
  Map<String, Path> provincePaths = {};
  String? _errorMessage;
  bool _isLoading = true;
  
  // For double tap zoom
  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
        debugPrint('Loaded ${paths.length} provinces');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading map: $e';
        _isLoading = false;
      });
      debugPrint('Error loading map: $e');
    }
  }

  void _handleDoubleTap() {
    if (_doubleTapPosition == null) return;
    
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = currentScale * 1.1; // Increase zoom by 10%
    
    // Get the position in the coordinate space before scaling
    final position = _transformationController.toScene(_doubleTapPosition!);
    
    // Create a new matrix for the transformation
    final matrix = Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..scale(targetScale)
      ..translate(-position.dx, -position.dy);
    
    _animateMatrix(_transformationController.value, matrix);
  }

  void _handleZoom(double scaleDelta) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = currentScale * scaleDelta;
    
    // Get the center of the screen
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    
    // Get the position in the coordinate space before scaling
    final position = _transformationController.toScene(center);
    
    // Create a new matrix for the transformation
    final matrix = Matrix4.identity()
      ..translate(position.dx, position.dy)
      ..scale(targetScale)
      ..translate(-position.dx, -position.dy);
    
    _animateMatrix(_transformationController.value, matrix);
  }

  void _animateMatrix(Matrix4 from, Matrix4 to) {
    _animation?.removeListener(_onAnimate);
    _animation = Matrix4Tween(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animation!.addListener(_onAnimate);
    _animationController.forward(from: 0);
  }

  void _onAnimate() {
    if (_animation == null) return;
    _transformationController.value = _animation!.value;
    if (!_animationController.isAnimating) {
      _animation?.removeListener(_onAnimate);
      _animation = null;
      _initialMatrix = null;
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

    if (provincePaths.isEmpty) {
      return const Center(
        child: Text(
          'No provinces loaded',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        ClipRect(
          child: GestureDetector(
            onDoubleTapDown: (details) {
              _doubleTapPosition = details.localPosition;
            },
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              panEnabled: true,
              scaleEnabled: true,
              onInteractionStart: _onInteractionStart,
              onInteractionEnd: _onInteractionEnd,
              child: CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ),
                painter: MapPainter(
                  nation: widget.nation,
                  selectedProvince: selectedProvince,
                  provincePaths: provincePaths,
                ),
              ),
            ),
          ),
        ),
        // Zoom controls
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: () => _handleZoom(1.1),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () => _handleZoom(0.9),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _initialMatrix = _transformationController.value;
    _animation?.removeListener(_onAnimate);
    _animationController.stop();
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Reset zoom if too far out
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale < 0.5) {
      final resetMatrix = Matrix4.identity();
      _animateMatrix(_transformationController.value, resetMatrix);
    }
  }

  void _onTapDown(TapDownDetails details) {
    final mapPoint = _transformationController.toScene(details.localPosition);
    
    // Check which province was tapped
    for (final province in widget.nation.provinces) {
      if (_mapService.isPointInProvince(mapPoint, province.id)) {
        setState(() {
          selectedProvince = province;
        });
        break;
      }
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
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

    // Calculate bounds of ALL paths
    Rect fullBounds = provincePaths.values.first.getBounds();
    for (final path in provincePaths.values.skip(1)) {
      fullBounds = fullBounds.expandToInclude(path.getBounds());
    }

    // Calculate scale to fit everything
    final scaleX = size.width / fullBounds.width;
    final scaleY = size.height / fullBounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final scaledScale = scale * 0.8; // Leave more margin for zooming

    // Center the entire map
    canvas.save();
    
    // Calculate translation to center the map
    final scaledWidth = fullBounds.width * scaledScale;
    final scaledHeight = fullBounds.height * scaledScale;
    final dx = (size.width - scaledWidth) / 2 - fullBounds.left * scaledScale;
    final dy = (size.height - scaledHeight) / 2 - fullBounds.top * scaledScale;
    
    canvas.translate(dx, dy);
    canvas.scale(scaledScale);

    // Draw background
    final backgroundPaint = Paint()
      ..color = const Color(0xFFADD8E6) // Light blue for water
      ..style = PaintingStyle.fill;
    canvas.drawRect(fullBounds, backgroundPaint);

    // Draw provinces
    final provincePaint = Paint()
      ..color = const Color(0xFFE8E8E8) // Light grey for land
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      // Keep this very low
      ..strokeWidth = 0.1;

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