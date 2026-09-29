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

/// Brand orange for TYPE AND ICONS on a light surface.
///
/// [kBrand] measures about 2.7:1 against white — under WCAG AA's 4.5:1 for
/// text and even under the 3:1 for a UI component — so it may only be used as
/// a fill behind white, never as the foreground itself. This one clears 5.3:1
/// on white and 4.9:1 on [kDaylight].
const Color kBrandDeep = Color(0xFFB34C05);

/// The deep brown the app writes with — type, icons, hairlines.
const Color kInk = Color(0xFF120A04);

/// The warm cream every page settles into.
const Color kDaylight = Color(0xFFFFF3E6);

/// Errors on a dark surface — the usual blood red vibrates there.
const Color kBrandError = Color(0xFFFF8A7A);

/// Errors on a light surface. [kBrandError] is a tint lifted for dark
/// backdrops and has nowhere near enough contrast against white.
const Color kBrandErrorDeep = Color(0xFFC0342B);

/// A frosted pane for chrome that floats over live content: the map's status
/// card, its recenter button and its nav capsule.
///
/// White, and deliberately near-opaque. A pale pane over pale map tiles has
/// almost nothing to separate it from the background, so the separation has to
/// come from somewhere: [opacity] carries most of it, with an ink hairline and
/// a soft shadow doing the rest. Lowering [opacity] much below the default
/// undoes that and the pane starts to dissolve into the tiles.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = EdgeInsets.zero,
    this.opacity = 0.86,
    this.blur = 16,
    this.borderOpacity = 0.10,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// How opaque the white is. Raise it where type has to stay legible over
  /// busy tiles, lower it only where the pane is purely decorative.
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
                  color: kInk.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
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
              color: Colors.white.withValues(alpha: opacity),
              border: Border.all(
                color: kInk.withValues(alpha: borderOpacity),
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
