import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';

/// "Help type" toggle (free vs bounty), the reward-explainer box, and —
/// only in bounty mode — the editable amount field and quick-add chips.
class BountySectionWidget extends ConsumerWidget {
  const BountySectionWidget({super.key, required this.bountyController});

  final TextEditingController bountyController;

  void _addBounty(WidgetRef ref, double amount) {
    final updated =
        ref.read(lostPetPostFormProvider.notifier).addBounty(amount);
    bountyController.text = updated.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBountyMode = ref.watch(
      lostPetPostFormProvider.select((state) => state.isBountyMode),
    );
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 6. ตัวเลือกประเภทความช่วยเหลือ (Help Type Toggle)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              _buildModeToggleButton(
                selected: !isBountyMode,
                icon: Icons.favorite,
                label: 'HELP FREE',
                activeColor: Colors.green,
                onTap: () => notifier.updateBountyMode(false),
              ),
              _buildModeToggleButton(
                selected: isBountyMode,
                icon: Icons.monetization_on_outlined,
                label: 'BOUNTY',
                activeColor: Colors.orange,
                onTap: () => notifier.updateBountyMode(true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 7. กล่องคำอธิบายรางวัล (สลับแสดงตาม Help Free หรือ Bounty)
        if (!isBountyMode)
          _buildRewardInfoBox(
            background: const Color(0xFFF1F8F5),
            border: const Color(0xFF81C784),
            icon: Icons.workspace_premium,
            accent: Colors.green,
            title: 'XP REWARD ONLY',
            description:
                'Hunters will receive Trust Score and XP points for successful findings, but no cash reward will be issued.',
          )
        else ...[
          _buildRewardInfoBox(
            background: const Color(0xFFFFFDF5),
            border: const Color(0xFFFFEEBA),
            icon: Icons.flash_on,
            accent: Colors.brown,
            title: 'CASH REWARD + XP',
            description:
                'Hunters will receive the full cash bounty PLUS Trust Score and XP points upon successful verification.',
          ),
          const SizedBox(height: 16),

          // 8. ส่วนแสดงจำนวนเงินรางวัลแบบพิมพ์ได้ (Editable Bounty Input)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: bountyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                    onChanged: (value) {
                      final amount =
                          double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                      notifier.updateBountyAmount(amount);
                    },
                    validator: (value) {
                      if (!isBountyMode) return null;
                      if (value == null || value.isEmpty) return 'Required';
                      final parsed = double.tryParse(value.replaceAll(',', ''));
                      if (parsed == null) return 'Invalid amount';
                      if (parsed < 0) return 'Bounty cannot be negative';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ปุ่มลัดเพิ่มจำนวนเงินรางวัล
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBountyChip(ref, '+1,000', 1000),
              _buildBountyChip(ref, '+5,000', 5000),
              _buildBountyChip(ref, '+10,000', 10000),
            ],
          ),
        ],
      ],
    );
  }

  /// The "HELP FREE" / "BOUNTY" toggle segment — a single parameterized
  /// builder instead of two copy-pasted blocks that only differed in
  /// selected-flag, icon, color, and label.
  Widget _buildModeToggleButton({
    required bool selected,
    required IconData icon,
    required String label,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? activeColor : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The green "XP REWARD ONLY" / orange "CASH REWARD + XP" explainer box —
  /// one parameterized builder instead of two copy-pasted blocks.
  Widget _buildRewardInfoBox({
    required Color background,
    required Color border,
    required IconData icon,
    required Color accent,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: accent, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBountyChip(WidgetRef ref, String label, double amount) {
    return InkWell(
      onTap: () => _addBounty(ref, amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
