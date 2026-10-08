import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_glass.dart';
import '../../../../core/ui/brand_widgets.dart';
import '../../domain/models/profile_models.dart';

/// One report the owner posted. Tapping it opens the report's sightings.
class OwnerPostCard extends StatelessWidget {
  const OwnerPostCard({
    super.key,
    required this.item,
    required this.onViewSightingsPressed,
    this.onEditPressed,
  });

  final OwnerPostHistoryItem item;
  final VoidCallback onViewSightingsPressed;

  /// Owner edits this report. Null hides the button — the caller only
  /// wires it for reports still being searched for.
  final VoidCallback? onEditPressed;

  static final NumberFormat _baht = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final (String state, Color stateColor) = switch (item.status) {
      PostStatus.activeSearch => ('Still searching', kBrandDeep),
      PostStatus.rescued => ('Home', kSuccessDeep),
      PostStatus.expired => ('Expired', kInk.withValues(alpha: 0.55)),
    };
    final n = item.receivedEntriesCount;
    final sightings = n == 1 ? '1 sighting' : '$n sightings';
    final active = item.status == PostStatus.activeSearch;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onViewSightingsPressed,
        child: SheetTile(
          highlight: active && n > 0,
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: HeroPhoto(imageUrl: item.petImageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: kInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$state, $sightings',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: stateColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Posted ${item.postedAtFormatted}',
                      style: TextStyle(fontSize: 13, color: kInk.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _baht.format(item.bountyReward),
                    style: displayStyle(
                        size: 20,
                        color: active ? kInk : kInk.withValues(alpha: 0.5)),
                  ),
                  Text('THB',
                      style: TextStyle(fontSize: 12, color: kInk.withValues(alpha: 0.55))),
                ],
              ),
              if (onEditPressed != null)
                IconButton(
                  tooltip: 'Edit report',
                  icon: Icon(Icons.edit_outlined, color: kInk.withValues(alpha: 0.7)),
                  onPressed: onEditPressed,
                )
              else
                const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
