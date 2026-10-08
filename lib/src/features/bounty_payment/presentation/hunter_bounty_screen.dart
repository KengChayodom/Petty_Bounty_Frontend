import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_glass.dart';
import '../../../core/ui/brand_widgets.dart';
import '../data/bounty_repository.dart';
import '../data/models/bounty_models.dart';
import '../domain/providers/bounty_providers.dart';
import 'widgets/bounty_notice.dart';

/// The returning hunter's side of one bounty: check the owner's payment and
/// confirm or dispute it, or refer the report as unpaid when nothing arrives.
class HunterBountyScreen extends ConsumerStatefulWidget {
  const HunterBountyScreen({super.key, required this.petId, this.now});

  final String petId;

  /// The clock, injectable so the three-day windows can be tested.
  final DateTime Function()? now;

  @override
  ConsumerState<HunterBountyScreen> createState() => _HunterBountyScreenState();
}

class _HunterBountyScreenState extends ConsumerState<HunterBountyScreen> {
  bool _busy = false;
  static final NumberFormat _baht = NumberFormat('#,##0.##');

  DateTime get _now => (widget.now ?? DateTime.now)();

  Future<void> _act(Future<void> Function(BountyRepository r) action, String done) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(bountyRepositoryProvider));
      _snack(done);
    } on BountyConflict catch (e) {
      _snack(e.message);
    } on BountyNotFound catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      // `ref` must not be used once the screen is gone.
      if (mounted) {
        setState(() => _busy = false);
        ref.invalidate(bountyViewProvider(widget.petId));
        ref.invalidate(myBountiesProvider);
      }
    }
  }

  Future<bool> _confirmDialog(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    return ok == true;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bountyViewProvider(widget.petId));
    return async.when(
      loading: () => const Scaffold(
        backgroundColor: kDaylight,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: kDaylight,
        appBar: AppBar(backgroundColor: kDaylight, foregroundColor: kInk, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is BountyNotFound
                ? 'This reward is not available to you.'
                : 'Could not load the reward. Pull down to try again.'),
          ),
        ),
      ),
      data: (v) => PhotoHeroScaffold(
        imageUrl: v.imageUrl,
        title: v.petName ?? 'Your reward',
        subtitle: 'Your reward for bringing them home',
        heroHeight: 300,
        onRefresh: () async => ref.invalidate(bountyViewProvider(widget.petId)),
        trailingTitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_baht.format(v.bountyAmount),
                style: displayStyle(size: 36, color: kBrandLight)),
            const SizedBox(height: 4),
            Text('THB', style: TextStyle(fontSize: 13, color: kDaylight.withValues(alpha: 0.85))),
          ],
        ),
        children: _body(v),
      ),
    );
  }

  List<Widget> _body(BountyView v) {
    final p = v.payment;
    if (v.bountyUnpaid) {
      return const [
        BountyNotice(
          icon: Icons.gavel_rounded,
          tone: BountyNoticeTone.warning,
          title: 'Closed as unpaid',
          body: 'An administrator closed this report with the bounty unpaid.',
        ),
      ];
    }
    if (p != null && p.isConfirmed) {
      return const [
        BountyNotice(
          icon: Icons.verified_rounded,
          tone: BountyNoticeTone.success,
          title: 'Paid',
          body: 'The bounty payment is confirmed.',
        ),
      ];
    }
    if (p != null && p.isAwaiting) {
      return [
        BountyNotice(
          icon: p.isDisputed ? Icons.report_rounded : Icons.payments_rounded,
          tone: p.isDisputed ? BountyNoticeTone.warning : BountyNoticeTone.info,
          title: p.isDisputed
              ? 'You reported the money has not arrived'
              : 'The owner says they have paid',
          body: p.isDisputed
              ? 'An administrator will check the slip and contact you.'
              : 'Check your bank account, then confirm. If you do nothing, an '
                  'administrator will review it after three days.',
        ),
        const SizedBox(height: 22),
        if (p.slipImageUrl != null) ...[
          const SheetHeading('Transfer slip'),
          const SizedBox(height: 10),
          SheetTile(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: p.slipImageUrl!, fit: BoxFit.contain, height: 320),
            ),
          ),
        ],
        if (p.referenceNo != null) ...[
          const SizedBox(height: 8),
          Text('Reference ${p.referenceNo}', style: TextStyle(fontSize: 14, color: kInk.withValues(alpha: 0.65))),
        ],
        const SizedBox(height: 22),
        _button(
          label: 'The money arrived',
          icon: Icons.check_circle_rounded,
          onPressed: () async {
            if (await _confirmDialog('Confirm the payment?',
                'This closes the case. Only confirm once the money is in your account.')) {
              await _act((r) => r.answerPayment(p.id, confirm: true), 'Payment confirmed.');
            }
          },
        ),
        if (p.canDispute(_now)) ...[
          const SizedBox(height: 10),
          _button(
            label: 'It did not arrive',
            danger: true,
            icon: Icons.report_gmailerrorred_rounded,
            outlined: true,
            onPressed: () async {
              if (await _confirmDialog('Report the money as not received?',
                  'An administrator will review the slip.')) {
                await _act((r) => r.answerPayment(p.id, confirm: false), 'Sent to an administrator.');
              }
            },
          ),
        ],
      ];
    }
    // Nothing paid yet.
    return [
      if (v.isReferredUnpaid)
        const BountyNotice(
          icon: Icons.flag_rounded,
          tone: BountyNoticeTone.warning,
          title: 'Reported as unpaid',
          body: 'An administrator will contact the owner.',
        )
      else
        BountyNotice(
          icon: Icons.hourglass_top_rounded,
          title: p != null && p.isRejected
              ? 'The owner\'s payment was rejected'
              : 'Waiting for the owner to pay',
          body: 'Make sure the phone number on your profile is your PromptPay mobile number.',
        ),
      if (v.canReferUnpaid(_now)) ...[
        const SizedBox(height: 20),
        _button(
          label: 'Report unpaid',
          icon: Icons.flag_rounded,
          outlined: true,
          danger: true,
          onPressed: () async {
            if (await _confirmDialog('Report the bounty as unpaid?',
                'An administrator will contact the owner.')) {
              await _act((r) => r.referUnpaid(widget.petId), 'Reported to an administrator.');
            }
          },
        ),
      ],
    ];
  }

  Widget _button({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool outlined = false,
    bool danger = false,
  }) =>
      BrandButton(
        label: label,
        icon: icon,
        outlined: outlined,
        danger: danger,
        onPressed: _busy ? null : onPressed,
      );
}
