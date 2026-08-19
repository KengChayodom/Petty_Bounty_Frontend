import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'skeleton_effects.dart';

/// The "work in flight over a photo" state: a dim scrim with shimmering bars
/// standing in for the result that is about to land, plus a plain-text label.
///
/// Replaces the spinner-over-photo pattern in the camera, the verification
/// screen, and the lost-pet photo picker. The bars are deliberately laid out
/// like the two lines of result text (species + confidence) the analysis
/// returns, so the placeholder previews the answer's shape.
class SkeletonAnalysisOverlay extends StatelessWidget {
  const SkeletonAnalysisOverlay({
    super.key,
    required this.label,
    this.subLabel,
    this.borderRadius,
    this.compact = false,
  });

  /// Primary line of copy, e.g. 'AI is analyzing...'.
  final String label;

  /// Optional second, quieter line, e.g. what the user should expect next.
  final String? subLabel;

  /// Match the radius of whatever the overlay is drawn on top of, so the scrim
  /// does not square off a rounded photo.
  final BorderRadius? borderRadius;

  /// Tighter bars + smaller type, for a thumbnail-sized slot rather than a
  /// full-screen photo.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double barHeight = compact ? 9 : 12;
    final double wideBar = compact ? 110 : 180;
    final double narrowBar = compact ? 70 : 120;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: ColoredBox(
        color: const Color(0xB3000000),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Skeletonizer.zone(
              effect: AppSkeletons.onDark,
              // Inside a zone only Bones are shaded, so the labels below
              // render as real text without needing a Skeleton.keep.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Bone(
                    width: wideBar,
                    height: barHeight,
                    uniRadius: barHeight / 2,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Bone(
                    width: narrowBar,
                    height: barHeight,
                    uniRadius: barHeight / 2,
                  ),
                  SizedBox(height: compact ? 14 : 22),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 12 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subLabel!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
