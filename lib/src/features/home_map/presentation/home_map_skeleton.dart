import 'package:flutter/material.dart';

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
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
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
              child: const Bone.circle(size: 40),
            ),

            // Capsule bottom nav.
            Positioned(
              left: 16,
              right: 16,
              bottom: padding.bottom + 16,
              child: const Bone(height: 65, uniRadius: 35),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  caption,
                  style: TextStyle(
                    color: Colors.grey[700],
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
