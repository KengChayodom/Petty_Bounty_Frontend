import 'package:flutter/material.dart';

import '../../../../core/ui/skeleton/skeleton.dart';

/// The modal shown while a missing-pet report is uploaded and broadcast.
///
/// Instead of a spinner it shows a skeleton of the poster being built — a photo
/// slot, a title line and two detail lines — so the wait previews the artefact
/// the user is creating. The two lines of copy carry the actual status.
class BroadcastProgressDialog extends StatelessWidget {
  const BroadcastProgressDialog({
    super.key,
    this.title = 'Broadcasting missing pet report...',
    this.subtitle = 'Please wait while AI processes your poster',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Skeletonizer.zone(
              child: Column(
                children: [
                  Bone(height: 96, uniRadius: 14),
                  SizedBox(height: 14),
                  Bone(width: 140, height: 14, uniRadius: 7),
                  SizedBox(height: 8),
                  Bone(height: 10, uniRadius: 5),
                  SizedBox(height: 6),
                  Bone(width: 120, height: 10, uniRadius: 5),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
