import 'package:flutter/material.dart';

/// A button that is used throughout the app.
class MyButton extends StatelessWidget {
  /// Creates a new button.
  const MyButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  /// The callback that is called when the button is pressed.
  final VoidCallback onPressed;

  /// The child widget of the button.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: child,
    );
  }
} 