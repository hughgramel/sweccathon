import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game_types.dart';
import '../widgets/interactive_map.dart';
import '../widgets/resource_bar.dart';

class GameViewScreen extends StatelessWidget {
  final Nation nation;

  const GameViewScreen({
    super.key,
    required this.nation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom layer: Grid background
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),

          // Second layer: Interactive map
          InteractiveMap(nation: nation),
          
          // Top layers: UI elements
          Column(
            children: [
              // Top bar with back button
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/scenarios'),
                      ),
                      Expanded(child: ResourceBar(nation: nation)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Grid painter for background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
} 