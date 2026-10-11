import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';
import '../../../../core/ui/brand_widgets.dart';

/// One career number on the profile: a large figure over a short label.
class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({
    super.key,
    required this.numberText,
    required this.label,
    this.highlight = false,
  });

  final String numberText;
  final String label;

  /// The figure in brand orange: the one number this tab leads with.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SheetTile(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            numberText,
            maxLines: 1,
            style: displayStyle(size: 28, color: highlight ? kBrandDeep : kInk),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: kInk.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}
