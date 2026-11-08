import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../../domain/models/profile_models.dart';

/// One sighting the hunter sent: what they saw, when, what the owner said,
/// and the points it earned.
class HunterHistoryCard extends StatelessWidget {
  const HunterHistoryCard({super.key, required this.item});

  final HunterSightingHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final (String verdict, Color verdictColor) = switch (item.status) {
      SightingStatus.verified => ('Owner confirmed', kSuccessDeep),
      SightingStatus.waitingVerified => ('Waiting for the owner', kBrandDeep),
      SightingStatus.unmatch => ('Not their pet', kInk.withValues(alpha: 0.55)),
    };

    final String points = item.points != null
        ? '+${item.points}'
        : item.isDuplicate
            ? 'Duplicate'
            : item.status == SightingStatus.unmatch
                ? '0'
                : '';

    return SheetTile(
      key: ValueKey('hunter-history-${item.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: HeroPhoto(imageUrl: item.petImageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // The hunter's action: seen, or caught (the one a reward
                  // can follow).
                  '${item.detectedSpecies} ${item.isCaught ? 'caught' : 'seen'}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kInk),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sentAtFormatted,
                  style: TextStyle(fontSize: 13, color: kInk.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  verdict,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: verdictColor),
                ),
              ],
            ),
          ),
          if (points.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              points,
              style: item.points != null
                  ? displayStyle(size: 20, color: kBrandDeep)
                  : TextStyle(fontSize: 13, color: kInk.withValues(alpha: 0.55)),
            ),
          ],
        ],
      ),
    );
  }
}
