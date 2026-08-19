import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'skeleton_effects.dart';

/// The in-button pending state: a shimmering bar where the label sits, used in
/// place of the "spinner inside the button" pattern.
///
/// Drop it in as the button's `child` while the action runs (the button itself
/// should already be disabled by passing `onPressed: null`):
///
/// ```dart
/// ElevatedButton(
///   onPressed: submitting ? null : _submit,
///   child: submitting
///       ? const BusyButtonLabel(width: 120)
///       : const Text('BROADCAST CASE'),
/// )
/// ```
///
/// [Skeletonizer.zone] is used rather than plain `Skeletonizer` because only
/// the [Bone] should be shaded — a zone leaves any sibling real widget alone.
class BusyButtonLabel extends StatelessWidget {
  const BusyButtonLabel({
    super.key,
    this.width = 96,
    this.height = 14,
    this.effect,
  });

  /// Roughly the width of the label being replaced, so the button does not
  /// change size when the action starts.
  final double width;

  final double height;

  /// Defaults to [AppSkeletons.onAccent] — white-on-brand. Pass
  /// [AppSkeletons.onSurface] for a light/outlined button.
  final PaintingEffect? effect;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      effect: effect ?? AppSkeletons.onAccent,
      child: Bone(width: width, height: height, uniRadius: height / 2),
    );
  }
}

/// The circular sibling of [BusyButtonLabel], for a pending state that has to
/// fit a round slot — the avatar being uploaded in the edit-profile dialog.
class BusyCircle extends StatelessWidget {
  const BusyCircle({super.key, required this.size, this.effect});

  final double size;
  final PaintingEffect? effect;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      effect: effect ?? AppSkeletons.onAccent,
      child: Bone.circle(size: size),
    );
  }
}
