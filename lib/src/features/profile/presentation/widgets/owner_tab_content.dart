import 'package:flutter/material.dart';

import '../../domain/models/profile_models.dart';
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
  });

  final int postsCount;
  final int recoversCount;
  final List<OwnerPostHistoryItem> postItems;
  final ValueChanged<OwnerPostHistoryItem> onViewSightingsPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PET OWNER CAREERS HEADER
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PET OWNER CAREERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 12),

        // 2 STATS CARDS
        Row(
          children: [
            Expanded(
              child: ProfileStatCard(
                backgroundColor: const Color(0xFFFFAB91),
                icon: Icons.article_rounded,
                iconColor: Colors.white,
                numberText: '$postsCount',
                numberColor: Colors.white,
                label: 'POSTS',
                labelColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileStatCard(
                backgroundColor: const Color(0xFFE0F2F1),
                icon: Icons.volunteer_activism_rounded,
                iconColor: const Color(0xFF00BFA5),
                numberText: '$recoversCount',
                numberColor: const Color(0xFF00BFA5),
                label: 'RECOVERS',
                labelColor: const Color(0xFF00BFA5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // MY POSTED HEADER
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MY POSTED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            Icon(Icons.filter_list_rounded, color: Colors.black87),
          ],
        ),
        const SizedBox(height: 12),

        // MY POSTED LIST
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: postItems.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = postItems[index];
            return OwnerPostCard(
              item: item,
              onViewSightingsPressed: () => onViewSightingsPressed(item),
            );
          },
        ),
      ],
    );
  }
}
