import 'package:flutter/material.dart';

import '../../../core/theme/app_glass.dart';
import '../../../core/ui/skeleton/skeleton.dart';

/// Full-screen skeleton for the map tab's cold start — the window between app
/// launch and the first GPS fix, before `FlutterMap` can be given a centre.
///
/// It reserves the real screen's chrome (search card at the top, recenter
/// button, capsule nav bar at the bottom) over a flat map field, so the live
/// map slides in underneath furniture that is already in place. The caption is
/// plain text rather than an indicator: the user is told *why* they are
/// waiting, without a spinner.
class HomeMapSkeleton extends StatelessWidget {
  const HomeMapSkeleton({super.key, this.caption = 'Finding your location...'});

  final String caption;

  /// The muted field the map tiles will replace. Slightly blue-grey so it
  /// reads as a map surface rather than as a broken screen.
  static const _mapField = Color(0xFFE6EAF0);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: _mapField,
      body: Skeletonizer.zone(
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: _mapField)),

            // Search / summary card — mirrors `_buildSearchBar`.
            Positioned(
              top: padding.top + 16,
              left: 16,
              right: 16,
              child: const GlassSurface(
                opacity: 0.93,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Bone.icon(size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone(width: 152, height: 14, uniRadius: 7),
                            SizedBox(height: 6),
                            Bone(width: 108, height: 11, uniRadius: 5),
                          ],
                        ),
                      ),
                      Bone(width: 44, height: 28, uniRadius: 14),
                    ],
                  ),
                ),
              ),
            ),

            // Recenter button.
            Positioned(
              right: 16,
              bottom: padding.bottom + 110,
              child: const GlassSurface(
                borderRadius: BorderRadius.all(Radius.circular(22)),
                child: SizedBox(width: 44, height: 44),
              ),
            ),

            // Capsule bottom nav. The real bar's camera disc is reserved too,
            // so nothing shifts when the map arrives underneath.
            Positioned(
              left: 16,
              right: 16,
              bottom: padding.bottom + 16,
              child: const Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  GlassSurface(
                    borderRadius: BorderRadius.all(Radius.circular(35)),
                    // Width must be stated: a Stack loosens its children, so a
                    // bare height would let the bar collapse to nothing.
                    child: SizedBox(height: 65, width: double.infinity),
                  ),
                  Positioned(top: -18, child: Bone.circle(size: 70)),
                ],
              ),
            ),

            // Why the screen is empty. Real text, not a bone — this is the one
            // element that carries information rather than reserving space.
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kInk.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  caption,
                  style: TextStyle(
                    color: kInk.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
