import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_glass.dart';
import '../domain/promptpay_payload.dart';

/// The card a Pet Owner pays the bounty from, once their report is "Found".
///
/// Shows who is owed and how much, and a PromptPay QR code carrying the
/// hunter's number and that exact amount. The owner scans it in their banking
/// app; the transfer happens there, never in this app. When the hunter has not
/// registered a PromptPay number, the code is replaced by a note that their
/// payout details are awaited.
class BountyPaymentCard extends StatelessWidget {
  const BountyPaymentCard({
    super.key,
    required this.hunterName,
    required this.amount,
    required this.promptPayNumber,
    this.onAttachSlip,
  });

  final String hunterName;

  /// The bounty, in baht.
  final double amount;

  /// The returning hunter's PromptPay mobile number, or null when they have
  /// not registered one.
  final String? promptPayNumber;

  /// Called when the owner chooses to attach the transfer slip. Null disables
  /// the button, which is the state while no QR code can be shown.
  final VoidCallback? onAttachSlip;

  static final NumberFormat _baht = NumberFormat('#,##0.##');

  @override
  Widget build(BuildContext context) {
    final number = promptPayNumber;
    final canPay = number != null && PromptPayPayload.isValidMobile(number);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kInk.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: kInk.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pay the bounty to',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: kInk.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hunterName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kInk,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: _baht.format(amount),
              children: const [
                TextSpan(
                  text: ' THB',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: kBrandDeep,
            ),
          ),
          const SizedBox(height: 16),
          if (canPay) _QrPane(number: number, amount: amount) else const _AwaitingPane(),
          const SizedBox(height: 16),
          Text(
            canPay
                ? 'Scan with your banking app. Your bank will show the '
                    'hunter\'s name before you confirm the transfer.'
                : 'You can pay as soon as the hunter adds a PromptPay number.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: kInk.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: canPay ? onAttachSlip : null,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text(
                'Attach transfer slip',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kInk.withValues(alpha: 0.08),
                disabledForegroundColor: kInk.withValues(alpha: 0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPane extends StatelessWidget {
  const _QrPane({required this.number, required this.amount});

  final String number;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kInk.withValues(alpha: 0.10)),
      ),
      child: QrImageView(
        data: PromptPayPayload.build(number, amount: amount),
        size: 220,
        // A white quiet zone and pure black modules: banking apps read these
        // fastest, and a brand-coloured code is slower to scan in dim light.
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        semanticsLabel: 'PromptPay QR code',
      ),
    );
  }
}

class _AwaitingPane extends StatelessWidget {
  const _AwaitingPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      height: 248,
      decoration: BoxDecoration(
        color: kDaylight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kInk.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 40, color: kBrandDeep.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Waiting for the hunter\'s payout details',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kInk),
            ),
          ),
        ],
      ),
    );
  }
}
