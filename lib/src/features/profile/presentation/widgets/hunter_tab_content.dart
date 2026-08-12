import 'package:flutter/material.dart';

import '../../domain/models/profile_models.dart';
import 'hunter_history_card.dart';
import 'profile_stat_card.dart';

/// Hunter tab content view (Career stats + Sight sent history list).
class HunterTabContent extends StatelessWidget {
  const HunterTabContent({
    super.key,
    required this.earnedPoints,
    required this.sightingCount,
    required this.rescuesCount,
    required this.historyItems,
  });

  final int earnedPoints;
  final int sightingCount;
  final int rescuesCount;
  final List<HunterSightingHistoryItem> historyItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HUNTER CAREERS HEADER
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HUNTER CAREERS',
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

        // 3 STATS CARDS
        Row(
          children: [
            Expanded(
              child: ProfileStatCard(
                backgroundColor: const Color(0xFFFFF3E0),
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFB300),
                numberText: '$earnedPoints',
                numberColor: const Color(0xFFFF6D00),
                label: 'EARNED POINT',
                labelColor: const Color(0xFFFF6D00),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatCard(
                backgroundColor: const Color(0xFFF5F5F5),
                icon: Icons.search_rounded,
                iconColor: Colors.black87,
                numberText: '$sightingCount',
                numberColor: Colors.black87,
                label: 'SIGHTING',
                labelColor: Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatCard(
                backgroundColor: const Color(0xFFE8F5E9),
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFF4CAF50),
                numberText: '$rescuesCount',
                numberColor: const Color(0xFF2E7D32),
                label: 'RESCUES',
                labelColor: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // SIGHT SENT HISTORY HEADER
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SIGHT SENT HISTORY',
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

        // SIGHT SENT HISTORY LIST
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyItems.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return HunterHistoryCard(item: historyItems[index]);
          },
        ),
      ],
    );
  }
}
