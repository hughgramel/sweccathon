import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

class ScenariosScreen extends StatelessWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choose a Scenario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1914 Scenario Button
          InkWell(
            onTap: () => context.go('/country-list-1914'),
            child: Container(
              height: 240,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.file(
                    File('/Users/hughgramelspacher/repos/sweccathon/flutter-games-basic/assets/images/scenarios/civil_war_background.png'),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      // Try loading as asset if file loading fails
                      return Image.asset(
                        'assets/images/scenarios/civil_war_background.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading asset: $error');
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text(
                                'Error loading image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  // Darkened overlay with reduced opacity
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        // Text row at the top
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Year
                            Text(
                              '1914',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'MPLUS Rounded 1c',
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Era
                            Text(
                              'Age of Industrialization',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                fontFamily: 'MPLUS Rounded 1c',
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 