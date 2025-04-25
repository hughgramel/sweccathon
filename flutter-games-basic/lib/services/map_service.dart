import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:xml/xml.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  Map<String, Path>? _provincePaths;

  Future<Map<String, Path>> loadProvincePaths() async {
    if (_provincePaths != null) {
      debugPrint('Returning cached paths: ${_provincePaths!.length} provinces');
      debugPrint('Cached province IDs: ${_provincePaths!.keys.join(', ')}');
      return _provincePaths!;
    }

    debugPrint('=== Starting SVG Load ===');
    debugPrint('Loading SVG file...');
    final svgString = await rootBundle.loadString('assets/world_provinces.svg');
    debugPrint('SVG file loaded, length: ${svgString.length}');
    
    final paths = <String, Path>{};

    try {
      final document = XmlDocument.parse(svgString);
      final pathElements = document.findAllElements('path');
      debugPrint('Found ${pathElements.length} path elements');
      
      // Get SVG viewBox to properly scale paths
      final svg = document.findElements('svg').first;
      final viewBox = svg.getAttribute('viewBox')?.split(' ').map(double.parse).toList();
      debugPrint('SVG viewBox: $viewBox');
      
      int pathIndex = 0;
      for (final pathElement in pathElements) {
        final id = pathElement.getAttribute('id');
        final pathData = pathElement.getAttribute('d');

        if (id != null && pathData != null) {
          debugPrint('Processing path $pathIndex - ID: $id');
          debugPrint('Path data length: ${pathData.length}');
          
          final path = Path();
          writeSvgPathDataToPath(
            pathData,
            SvgPathProxy(path),
          );
          
          // If viewBox is available, scale the path accordingly
          if (viewBox != null && viewBox.length == 4) {
            final matrix = Matrix4.identity();
            matrix.scale(1.0 / viewBox[2], 1.0 / viewBox[3]); // Scale to 0-1 range
            path.transform(matrix.storage);
          }
          
          final bounds = path.getBounds();
          debugPrint('Path $id bounds: $bounds');
          
          paths[id] = path;
          pathIndex++;
        }
      }
      
      debugPrint('=== SVG Load Summary ===');
      debugPrint('Successfully parsed ${paths.length} paths');
      debugPrint('Path IDs: ${paths.keys.join(', ')}');
    } catch (e) {
      debugPrint('Error parsing SVG: $e');
      debugPrint('SVG content preview: ${svgString.substring(0, min(200, svgString.length))}...');
      rethrow;
    }

    _provincePaths = paths;
    return paths;
  }

  Path? getProvincePath(String provinceId) {
    return _provincePaths?[provinceId];
  }

  bool isPointInProvince(Offset point, String provinceId) {
    final path = getProvincePath(provinceId);
    if (path == null) return false;
    return path.contains(point);
  }
}

class SvgPathProxy extends PathProxy {
  final Path path;

  SvgPathProxy(this.path);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

int min(int a, int b) => a < b ? a : b; 