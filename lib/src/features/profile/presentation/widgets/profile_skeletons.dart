import 'package:flutter/material.dart';

import '../../../../core/ui/skeleton/skeleton.dart';
import '../../domain/models/profile_models.dart';
import 'hunter_tab_content.dart';
import 'owner_tab_content.dart';
import 'profile_header_widget.dart';

/// Skeleton placeholders for the profile screen.
///
/// Each one renders the **real** widget with mock data inside a
/// [Skeletonizer], rather than hand-drawing an approximation of it. That means
/// the placeholder is laid out by exactly the code that lays out the loaded
/// state, so it cannot drift out of sync when the real widget changes.
///
/// Mock values only have to be *plausibly sized* — skeletonizer measures the
/// text and paints a bone over it, it never shows the characters.

/// Stands in for [ProfileHeaderWidget] while `userProfileProvider` resolves.
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ProfileHeaderWidget(
        displayName: BoneMock.name,
        phone: BoneMock.phone,
        email: BoneMock.email,
        onEditPressed: () {},
      ),
    );
  }
}

/// Stands in for [HunterTabContent] while the hunter stats + history load.
class HunterTabSkeleton extends StatelessWidget {
  const HunterTabSkeleton({super.key, this.itemCount = 3});

  /// How many placeholder history cards to show. Three fills a phone screen
  /// without implying a specific list length.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: HunterTabContent(
        earnedPoints: 1250,
        sightingCount: 24,
        rescuesCount: 6,
        historyItems: List.generate(
          itemCount,
          (i) => HunterSightingHistoryItem(
            id: 'skeleton-$i',
            detectedSpecies: 'Cat',
            // Null keeps CircleAvatar on its local fallback icon: a skeleton
            // must never kick off a network image fetch.
            petImageUrl: null,
            status: SightingStatus.waitingVerified,
            actionType: 'Spotted',
            points: 40,
            sentAtFormatted: BoneMock.date,
          ),
        ),
      ),
    );
  }
}

/// Stands in for [OwnerTabContent] while `ownerPostsProvider` resolves.
class OwnerTabSkeleton extends StatelessWidget {
  const OwnerTabSkeleton({super.key, this.itemCount = 2});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: OwnerTabContent(
        postsCount: 4,
        recoversCount: 2,
        postItems: List.generate(
          itemCount,
          (i) => OwnerPostHistoryItem(
            id: 'skeleton-$i',
            petName: BoneMock.name,
            petImageUrl: null,
            status: PostStatus.activeSearch,
            bountyReward: 1500,
            postedAtFormatted: BoneMock.date,
            receivedEntriesCount: 3,
          ),
        ),
        // Skeletonizer ignores pointers while enabled, so this is never
        // reachable; it exists only to satisfy the real widget's contract.
        onViewSightingsPressed: (_) {},
      ),
    );
  }
}
