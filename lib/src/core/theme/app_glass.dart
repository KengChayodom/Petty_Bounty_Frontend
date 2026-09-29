import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// The app's shared surface language: one brand orange, one ink, and the
/// frosted pane the chrome is built from.
///
/// These sit in `core` rather than in a feature because the map screen and the
/// auth screens had drifted apart — two different oranges and three unrelated
/// blues between them — and a token only ends that if there is exactly one of
/// it for the whole app to import.

/// Lifted straight off the puzzle-paw logo. The map screen used to carry its
/// own near-miss (`0xFFED7645`); this is the one.
const Color kBrand = Color(0xFFF7791E);

/// The lighter end of the brand gradient, and the tint for anything active.
const Color kBrandLight = Color(0xFFFFA24C);

/// The deep brown every dark surface in the app settles into.
const Color kInk = Color(0xFF120A04);

/// Errors on a dark surface — the usual blood red vibrates there.
const Color kBrandError = Color(0xFFFF8A7A);

/// A frosted pane for chrome that floats over live content: the map's status
/// card, its recenter button and its nav capsule.
///
/// Tinted with [kInk] rather than with white, because it is laid over map
/// tiles, which are light. A white pane on a light map has nothing to separate
/// it from the background; a dark one reads instantly and lets white type sit
/// on it at full contrast.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = EdgeInsets.zero,
    this.opacity = 0.62,
    this.blur = 16,
    this.borderOpacity = 0.16,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// How much ink the pane carries. Raise it where type has to stay legible
  /// over busy tiles, lower it where the pane is mostly decorative.
  final double opacity;

  final double blur;
  final double borderOpacity;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: kInk.withValues(alpha: opacity),
              border: Border.all(
                color: Colors.white.withValues(alpha: borderOpacity),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
