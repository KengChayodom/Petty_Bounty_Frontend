import 'package:flutter/material.dart';

import '../../domain/models/profile_models.dart';
import '../../../../core/ui/brand_widgets.dart';
import 'owner_post_card.dart';
import 'profile_stat_card.dart';

/// Pet Owner tab content view (Career stats + My posted list).
class OwnerTabContent extends StatelessWidget {
  const OwnerTabContent({
    super.key,
    required this.postsCount,
    required this.recoversCount,
    required this.postItems,
    required this.onViewSightingsPressed,
    this.onEditPressed,
  });

  final int postsCount;
  final int recoversCount;
  final List<OwnerPostHistoryItem> postItems;
  final ValueChanged<OwnerPostHistoryItem> onViewSightingsPressed;

  /// Owner edits a report. Returns null for a given item to hide the
  /// button (the caller only offers it for reports still being searched for).
  final VoidCallback? Function(OwnerPostHistoryItem item)? onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ProfileStatCard(
                numberText: '$postsCount',
                label: 'Reports',
                highlight: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatCard(
                numberText: '$recoversCount',
                label: 'Pets home',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SheetHeading('Your reports'),
        const SizedBox(height: 10),
        // MY POSTED LIST
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: postItems.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = postItems[index];
            return OwnerPostCard(
              item: item,
              onViewSightingsPressed: () => onViewSightingsPressed(item),
              onEditPressed: onEditPressed?.call(item),
            );
          },
        ),
      ],
    );
  }
}
