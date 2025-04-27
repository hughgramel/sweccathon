import 'package:flutter/material.dart';
import '../models/game_types.dart';

class MapPainter extends CustomPainter {
  final Nation nation;
  final Province? selectedProvince;
  final Map<String, Path> provincePaths;
  final Size canvasSize;

  MapPainter({
    required this.nation,
    this.selectedProvince,
    required this.provincePaths,
    required this.canvasSize,
  });

  String? getProvinceAtPoint(Offset point) {
    // Convert point to local coordinates (0-1 range)
    final normalizedPoint = Offset(
      point.dx / canvasSize.width,
      point.dy / canvasSize.height,
    );

    // Check each province path
    for (final entry in provincePaths.entries) {
      final path = entry.value;
      final bounds = path.getBounds();
      
      // Check if point is within the bounds of the path
      if (bounds.contains(point)) {
        // Create a simple hit test using path.contains
        if (path.contains(point)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey[200]!;

    // Draw all provinces
    for (final entry in provincePaths.entries) {
      final provinceId = entry.key;
      final path = entry.value;
      
      // Check if this province belongs to the nation
      final province = nation.provinces.firstWhere(
        (p) => p.id == provinceId,
        orElse: () => Province(
          id: provinceId,
          name: 'Unknown',
          path: '',
          population: 0,
          goldIncome: 0,
          industry: 0,
          buildings: [],
          resourceType: ResourceType.none,
          army: 0,
        ),
      );

      // Set province color based on ownership
      if (province.id == selectedProvince?.id) {
        paint.color = Colors.blue.withOpacity(0.5);
      } else if (nation.provinces.any((p) => p.id == provinceId)) {
        paint.color = Color(int.parse(nation.hexColor.substring(1), radix: 16) | 0xFF000000);
      } else {
        paint.color = Colors.grey[200]!;
      }

      // Draw the province
      canvas.drawPath(path, paint);
    }

    // Draw province borders
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 1.0;

    for (final path in provincePaths.values) {
      canvas.drawPath(path, borderPaint);
    }

    // Draw debug grid
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.nation != nation ||
           oldDelegate.selectedProvince != selectedProvince ||
           oldDelegate.provincePaths != provincePaths ||
           oldDelegate.canvasSize != canvasSize;
  }
} 