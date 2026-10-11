import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';

/// A one-line status panel used by both sides of a bounty payment.
class BountyNotice extends StatelessWidget {
  const BountyNotice({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.tone = BountyNoticeTone.info,
  });

  final IconData icon;
  final String title;
  final String? body;
  final BountyNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BountyNoticeTone.success => kSuccessDeep,
      BountyNoticeTone.warning => kBrandErrorDeep,
      BountyNoticeTone.info => kBrandDeep,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                if (body != null) ...[
                  const SizedBox(height: 4),
                  Text(body!,
                      style: TextStyle(
                          fontSize: 14, height: 1.4, color: kInk.withValues(alpha: 0.7))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum BountyNoticeTone { info, success, warning }
