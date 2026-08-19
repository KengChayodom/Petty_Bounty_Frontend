import 'package:flutter/material.dart';

import '../../../../core/ui/skeleton/skeleton.dart';

/// Skeleton for the camera screen while the `CameraController` initialises.
///
/// Uses [AppSkeletons.onDark] because the camera surface is black — the shared
/// light-grey shimmer would glare against it.
class CameraInitializingSkeleton extends StatelessWidget {
  const CameraInitializingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Skeletonizer.zone(
        effect: AppSkeletons.onDark,
        child: const Stack(
          children: [
            // Stands in for the live preview.
            Positioned.fill(child: Bone()),
            // Close button.
            Positioned(top: 50, left: 20, child: Bone.circle(size: 30)),
            // Shutter row: gallery / shutter / (empty trailing slot).
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Bone.square(size: 48, uniRadius: 12),
                  Bone.circle(size: 70),
                  SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the shutter row while a captured or picked photo is being prepared
/// for analysis. Sits in the same 40px-from-bottom slot as the real controls,
/// so the bar does not jump when the state flips.
class CameraBusyBar extends StatelessWidget {
  const CameraBusyBar({super.key, this.label = 'Preparing photo...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      effect: AppSkeletons.onDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Bone(width: 160, height: 12, uniRadius: 6),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
