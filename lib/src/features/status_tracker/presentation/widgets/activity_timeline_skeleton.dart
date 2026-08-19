import 'package:flutter/material.dart';

import '../../../../core/ui/skeleton/skeleton.dart';
import '../../data/models/sighting_activity.dart';
import 'activity_card.dart';

/// Skeleton for the "RECENT ACTIVITY" timeline on the status tracker.
///
/// Renders real [ActivityCard]s with mock sightings inside a [Skeletonizer], so
/// the left rail, the connector line and the card silhouette are all laid out
/// by the production widget — including the 180px photo slot, which is the
/// tallest part of the card and therefore the one worth reserving.
class ActivityTimelineSkeleton extends StatelessWidget {
  const ActivityTimelineSkeleton({super.key, this.itemCount = 2});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    // A fixed timestamp (never `now`) keeps the placeholder deterministic and
    // gives `timeFormatted` a realistic width to paint a bone over; a null
    // createdAt would collapse that row to nothing.
    final mock = SightingActivity(
      id: 'skeleton',
      hunterName: BoneMock.name,
      detectedSpecies: 'Cat',
      actionType: 'Spotted',
      verificationStatus: 'Pending',
      createdAt: DateTime(2024, 1, 1, 12),
    );

    return Skeletonizer(
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++)
            ActivityCard(
              item: mock,
              isFirst: i == 0,
              isLast: i == itemCount - 1,
            ),
        ],
      ),
    );
  }
}
