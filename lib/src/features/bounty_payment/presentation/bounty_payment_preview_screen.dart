import 'package:flutter/material.dart';

import '../../../core/theme/app_glass.dart';
import 'bounty_payment_card.dart';

/// TEMPORARY, debug builds only: shows [BountyPaymentCard] with numbers you type
/// in, so the QR code can be scanned with a real banking app before the payment
/// backend exists. Remove once the card is wired into the report's flow.
class BountyPaymentPreviewScreen extends StatefulWidget {
  const BountyPaymentPreviewScreen({super.key});

  @override
  State<BountyPaymentPreviewScreen> createState() =>
      _BountyPaymentPreviewScreenState();
}

class _BountyPaymentPreviewScreenState
    extends State<BountyPaymentPreviewScreen> {
  final _number = TextEditingController(text: '0812345678');
  final _amount = TextEditingController(text: '2000');
  bool _hasNumber = true;

  @override
  void dispose() {
    _number.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    return Scaffold(
      backgroundColor: kDaylight,
      appBar: AppBar(
        backgroundColor: kDaylight,
        foregroundColor: kInk,
        elevation: 0,
        title: const Text(
          'Bounty payment preview',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _number,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Hunter PromptPay number',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (THB)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hunter has registered a number'),
            value: _hasNumber,
            onChanged: (v) => setState(() => _hasNumber = v),
          ),
          const SizedBox(height: 8),
          if (amount > 0)
            BountyPaymentCard(
              hunterName: 'Khun B (test)',
              amount: amount,
              promptPayNumber: _hasNumber ? _number.text : null,
              onAttachSlip: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Slip upload arrives with the payment backend.'),
                ),
              ),
            )
          else
            const Text('Enter an amount above zero.'),
        ],
      ),
    );
  }
}
