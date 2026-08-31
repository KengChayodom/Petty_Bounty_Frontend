import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/profile_models.dart';

/// Card item widget for Owner Posted Missing Pet.
class OwnerPostCard extends StatelessWidget {
  const OwnerPostCard({
    super.key,
    required this.item,
    required this.onViewSightingsPressed,
    this.onEditPressed,
  });

  final OwnerPostHistoryItem item;
  final VoidCallback onViewSightingsPressed;

  /// Owner edits this report (SRS-61). Null hides the button — the caller only
  /// wires it for reports still being searched for.
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    Widget statusBadge;
    switch (item.status) {
      case PostStatus.activeSearch:
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.saved_search_rounded,
                  size: 14, color: Colors.redAccent),
              SizedBox(width: 4),
              Text(
                'ACTIVE SEARCH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        );
        break;
      case PostStatus.rescued:
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 14, color: Color(0xFF2E7D32)),
              SizedBox(width: 4),
              Text(
                'RESCUED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        );
        break;
      case PostStatus.expired:
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_disabled_rounded,
                  size: 14, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                'EXPIRED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
        break;
    }

    final bool isActive = item.status == PostStatus.activeSearch;
    final Color buttonBgColor =
        isActive ? const Color(0xFFEE6D33) : const Color(0xFF555555);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: item.petImageUrl != null
                      ? NetworkImage(item.petImageUrl!)
                      : null,
                  child: item.petImageUrl == null
                      ? const Icon(Icons.pets, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.petName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                statusBadge,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BOUNTY REWARD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '฿ ${currencyFormatter.format(item.bountyReward)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6D00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'POST AT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item.postedAtFormatted,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'RECEIVED ${item.receivedEntriesCount} ENTRIES',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF0000),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (onEditPressed != null) ...[
                  OutlinedButton.icon(
                    onPressed: onEditPressed,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text(
                      'EDIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF555555),
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: onViewSightingsPressed,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'VIEW SIGHTING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBgColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
