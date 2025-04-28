import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A customized button widget for the game's main menu
class GameButton extends StatefulWidget {
  /// The text to display on the button
  final String text;

  /// The emoji icon to display before the text
  final String emoji;

  /// The callback when the button is pressed
  final VoidCallback onPressed;

  /// Whether the button should be disabled
  final bool disabled;
  
  /// Background color of the button
  final Color backgroundColor;
  
  /// Shadow color of the button
  final Color shadowColor;

  const GameButton({
    super.key,
    required this.text,
    required this.emoji,
    required this.onPressed,
    this.disabled = false,
    this.backgroundColor = const Color(0xFF67b9e7),
    this.shadowColor = const Color(0xFF4792ba),
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (!widget.disabled) {
          setState(() {
            _isPressed = true;
          });
        }
      },
      onTapUp: (details) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      onTap: widget.disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          0,
          _isPressed ? 0 : -2.0,
          0,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: widget.disabled 
                ? widget.backgroundColor.withOpacity(0.1) 
                : widget.backgroundColor,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              offset: Offset(0, _isPressed ? 0 : 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Opacity(
          opacity: widget.disabled ? 0.5 : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Text(
                widget.text,
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 