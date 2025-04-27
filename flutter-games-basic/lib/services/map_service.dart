// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:xml/xml.dart';

// class MapService {
//   Future<Map<String, Path>> loadProvincePaths() async {
//     try {
//       // Load the SVG file
//       final String svgString = await rootBundle.loadString('assets/maps/world_provinces.svg');
//       final document = XmlDocument.parse(svgString);
      
//       final Map<String, Path> paths = {};
      
//       // Find all path elements in the SVG
//       final pathElements = document.findAllElements('path');
      
//       for (final pathElement in pathElements) {
//         final id = pathElement.getAttribute('id');
//         if (id != null) {
//           final pathData = pathElement.getAttribute('d');
//           if (pathData != null) {
//             paths[id] = _parseSvgPath(pathData);
//           }
//         }
//       }
      
//       return paths;
//     } catch (e) {
//       throw Exception('Failed to load province paths: $e');
//     }
//   }
  
//   Path _parseSvgPath(String pathData) {
//     final path = Path();
//     final commands = pathData.split(RegExp(r'(?=[A-Za-z])'));
    
//     for (final command in commands) {
//       if (command.isEmpty) continue;
      
//       final type = command[0];
//       final numbers = command.substring(1).trim().split(RegExp(r'[,\s]+'));
      
//       switch (type) {
//         case 'M':
//           path.moveTo(double.parse(numbers[0]), double.parse(numbers[1]));
//           break;
//         case 'L':
//           path.lineTo(double.parse(numbers[0]), double.parse(numbers[1]));
//           break;
//         case 'C':
//           path.cubicTo(
//             double.parse(numbers[0]), double.parse(numbers[1]),
//             double.parse(numbers[2]), double.parse(numbers[3]),
//             double.parse(numbers[4]), double.parse(numbers[5]),
//           );
//           break;
//         case 'Z':
//           path.close();
//           break;
//       }
//     }
    
//     return path;
//   }
// } 