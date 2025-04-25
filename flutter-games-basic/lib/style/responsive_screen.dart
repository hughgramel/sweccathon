import 'package:flutter/material.dart';

/// A widget that makes it easy to create a screen with a square-ish
/// main area and a menu area below.
class ResponsiveScreen extends StatelessWidget {
  /// This is the "hero" part of the screen.
  final Widget squarishMainArea;

  /// This is the menu part of the screen, usually at the bottom.
  final Widget rectangularMenuArea;

  /// How much space to put between the main area and menu.
  final double mainAreaPadding;

  const ResponsiveScreen({
    super.key,
    required this.squarishMainArea,
    required this.rectangularMenuArea,
    this.mainAreaPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        // The screen will be split into a vertical stack with the
        // main area on top and the menu area at the bottom.
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Padding around the main area.
            Padding(
              padding: EdgeInsets.all(mainAreaPadding),
              child: squarishMainArea,
            ),
            // The menu area gets all the remaining height.
            SizedBox(
              width: size.width,
              child: SafeArea(
                top: false,
                child: rectangularMenuArea,
              ),
            ),
          ],
        );
      },
    );
  }
} 