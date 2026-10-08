import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_glass.dart';
import '../../../core/ui/brand_widgets.dart';
import '../../../routing/app_router.dart';
import '../data/models/bounty_models.dart';
import '../domain/providers/bounty_providers.dart';

/// On the hunter's profile tab: the reports they returned the pet for, each
/// opening its bounty. Renders nothing when there are none, or on an error,
/// so it never disturbs the rest of the tab.
class MyBountiesSection extends ConsumerWidget {
  const MyBountiesSection({super.key});

  static final NumberFormat _baht = NumberFormat('#,##0.##');

  static String _label(HunterBounty b) {
    if (b.petStatus == 'Resolved') {
      return b.paymentStatus == 'Verified' ? 'Paid' : 'Closed';
    }
    return switch (b.paymentStatus) {
      'Pending_Verification' => 'Check the payment',
      _ => 'Waiting for payment',
    };
  }

  /// The rows that ask the hunter to do something get the orange outline.
  static bool _needsHunter(HunterBounty b) =>
      b.petStatus != 'Resolved' && b.paymentStatus == 'Pending_Verification';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(myBountiesProvider).valueOrNull ?? const <HunterBounty>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeading('Rewards'),
        const SizedBox(height: 10),
        for (final b in list) ...[
          _BountyRow(
            bounty: b,
            label: _label(b),
            amount: _baht.format(b.bountyAmount),
            highlight: _needsHunter(b),
            onTap: () => context.push('${AppRoutes.bounty}/${b.petId}'),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

class _BountyRow extends StatelessWidget {
  const _BountyRow({
    required this.bounty,
    required this.label,
    required this.amount,
    required this.highlight,
    required this.onTap,
  });

  final HunterBounty bounty;
  final String label;
  final String amount;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paid = label == 'Paid';
    final labelColor = highlight
        ? kBrandDeep
        : paid
            ? kSuccessDeep
            : kInk.withValues(alpha: 0.6);
    return Semantics(
      button: true,
      label: '${bounty.petName}, $amount baht, $label',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SheetTile(
            highlight: highlight,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: HeroPhoto(imageUrl: bounty.imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bounty.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                      const SizedBox(height: 2),
                      Text(label,
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(amount,
                    style: displayStyle(
                        size: 20,
                        color: paid || bounty.petStatus == 'Resolved'
                            ? kInk.withValues(alpha: 0.5)
                            : kInk)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
