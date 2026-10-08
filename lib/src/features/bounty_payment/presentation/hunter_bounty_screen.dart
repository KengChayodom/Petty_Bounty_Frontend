import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_glass.dart';
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
    return Scaffold(
      backgroundColor: kDaylight,
      appBar: AppBar(
        backgroundColor: kDaylight,
        foregroundColor: kInk,
        elevation: 0,
        title: const Text('Your bounty', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is BountyNotFound ? 'This bounty is not available.' : 'Could not load the bounty.'),
          ),
        ),
        data: (v) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text('${_baht.format(v.bountyAmount)} THB',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: kBrandDeep)),
            const SizedBox(height: 16),
            ..._body(v),
          ],
        ),
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
        const SizedBox(height: 16),
        if (p.slipImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(imageUrl: p.slipImageUrl!, fit: BoxFit.contain, height: 360),
          ),
        if (p.referenceNo != null) ...[
          const SizedBox(height: 8),
          Text('Reference: ${p.referenceNo}', style: TextStyle(color: kInk.withValues(alpha: 0.7))),
        ],
        const SizedBox(height: 20),
        _button(
          label: 'I received the money',
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
            label: 'Not received',
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
  }) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(30));
    final child = Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15));
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: _busy ? null : onPressed,
              icon: Icon(icon),
              label: child,
              style: OutlinedButton.styleFrom(foregroundColor: kBrandErrorDeep, shape: shape),
            )
          : ElevatedButton.icon(
              onPressed: _busy ? null : onPressed,
              icon: Icon(icon),
              label: child,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandDeep, foregroundColor: Colors.white, elevation: 0, shape: shape),
            ),
    );
  }
}
