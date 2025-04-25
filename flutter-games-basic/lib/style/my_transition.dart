import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom transition between screens.
Page<T> buildMyTransition<T>({
  required Widget child,
  required Color color,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
} 