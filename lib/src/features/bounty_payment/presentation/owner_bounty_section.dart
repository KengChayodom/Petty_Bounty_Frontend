import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/bounty_errors.dart';
import '../domain/entities/bounty_models.dart';
import '../domain/providers/bounty_providers.dart';
import 'bounty_payment_card.dart';
import 'widgets/bounty_notice.dart';

/// Picks the transfer slip. Replaceable in tests, where there is no gallery.
typedef SlipPicker = Future<String?> Function();

Future<String?> _pickFromGallery() async {
  final file = await ImagePicker()
      .pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
  return file?.path;
}

/// The owner's side of the bounty, shown on the Status Tracker once the search
/// has ended: the payment card while the bounty is owed, then the payment's
/// status. Renders nothing for a report with no bounty.
class OwnerBountySection extends ConsumerStatefulWidget {
  const OwnerBountySection({
    super.key,
    required this.petId,
    this.pickSlip = _pickFromGallery,
  });

  final String petId;
  final SlipPicker pickSlip;

  @override
  ConsumerState<OwnerBountySection> createState() => _OwnerBountySectionState();
}

class _OwnerBountySectionState extends ConsumerState<OwnerBountySection> {
  bool _busy = false;

  Future<void> _attachSlip() async {
    final path = await widget.pickSlip();
    if (path == null || !mounted) return;
    // Null means the owner dismissed the dialog: cancel. "Skip" returns an
    // empty string, which is sent as no reference.
    final reference = await _askReference();
    if (reference == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(bountyRepositoryProvider)
          .submitPayment(widget.petId, slipPath: path, referenceNo: reference);
      _snack('Slip sent. The hunter will confirm the payment.');
    } on BountyConflict catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Could not send the slip. Please try again.');
    } finally {
      // `ref` must not be used once the screen is gone.
      if (mounted) {
        setState(() => _busy = false);
        ref.invalidate(bountyViewProvider(widget.petId));
      }
    }
  }

  Future<String?> _askReference() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reference number (optional)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'From your transfer slip'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bountyViewProvider(widget.petId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      // A report with nothing to settle is simply not part of this section.
      error: (_, _) => const SizedBox.shrink(),
      data: (view) => _content(view),
    );
  }

  Widget _content(BountyView v) {
    if (v.bountyAmount <= 0) return const SizedBox.shrink();
    final hunter = v.hunterUsername ?? 'the hunter';
    final p = v.payment;

    if (v.bountyUnpaid) {
      return const BountyNotice(
        icon: Icons.gavel_rounded,
        tone: BountyNoticeTone.warning,
        title: 'Closed as unpaid',
        body: 'An administrator closed this report with the bounty unpaid.',
      );
    }
    if (p != null && p.isConfirmed) {
      return BountyNotice(
        icon: Icons.verified_rounded,
        tone: BountyNoticeTone.success,
        title: 'Bounty paid',
        body: '$hunter confirmed the payment. This case is complete.',
      );
    }
    if (p != null && p.isAwaiting) {
      return BountyNotice(
        icon: p.isDisputed ? Icons.report_rounded : Icons.hourglass_top_rounded,
        tone: p.isDisputed ? BountyNoticeTone.warning : BountyNoticeTone.info,
        title: p.isDisputed
            ? 'The hunter says the money has not arrived'
            : 'Waiting for $hunter to confirm',
        body: p.isDisputed
            ? 'An administrator will check your slip and contact you.'
            : 'Your slip was sent. If $hunter does not answer within three days, '
                'an administrator will review it.',
      );
    }
    if (!v.unpaid) return const SizedBox.shrink();

    return Column(
      children: [
        if (p != null && p.isRejected) ...[
          const BountyNotice(
            icon: Icons.error_outline_rounded,
            tone: BountyNoticeTone.warning,
            title: 'Your last payment was rejected',
            body: 'An administrator could not confirm it. Please pay again.',
          ),
          const SizedBox(height: 12),
        ],
        if (v.isReferredUnpaid) ...[
          const BountyNotice(
            icon: Icons.flag_rounded,
            tone: BountyNoticeTone.warning,
            title: 'The hunter reported this bounty as unpaid',
            body: 'Pay now to close the report.',
          ),
          const SizedBox(height: 12),
        ],
        Stack(
          alignment: Alignment.center,
          children: [
            BountyPaymentCard(
              hunterName: hunter,
              amount: v.bountyAmount,
              promptPayNumber: v.hunterPromptPay,
              onAttachSlip: _busy ? null : _attachSlip,
            ),
            if (_busy) const CircularProgressIndicator(),
          ],
        ),
      ],
    );
  }
}
