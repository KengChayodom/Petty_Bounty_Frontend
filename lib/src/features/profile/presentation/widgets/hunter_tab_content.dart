import 'package:flutter/material.dart';

import '../../domain/models/profile_models.dart';
import '../../../bounty_payment/presentation/my_bounties_section.dart';
import '../../../../core/ui/brand_widgets.dart';
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ProfileStatCard(
                numberText: '$earnedPoints',
                label: 'Points',
                highlight: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatCard(
                numberText: '$sightingCount',
                label: 'Sightings',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ProfileStatCard(
                numberText: '$rescuesCount',
                label: 'Pets home',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Bounties the hunter is owed or has been paid (Feature 6).
        const MyBountiesSection(),
        const SheetHeading('Your sightings'),
        const SizedBox(height: 10),
        // SIGHT SENT HISTORY LIST
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyItems.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return HunterHistoryCard(item: historyItems[index]);
          },
        ),
      ],
    );
  }
}
