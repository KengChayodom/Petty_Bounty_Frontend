import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_glass.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(myBountiesProvider).valueOrNull ?? const <HunterBounty>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BOUNTIES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        for (final b in list)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: kInk.withValues(alpha: 0.08)),
            ),
            child: ListTile(
              leading: const Icon(Icons.payments_rounded, color: kBrandDeep),
              title: Text(b.petName, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${_baht.format(b.bountyAmount)} THB · ${_label(b)}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('${AppRoutes.bounty}/${b.petId}'),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
