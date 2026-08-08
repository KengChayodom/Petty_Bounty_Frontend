import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';

/// Primary color swatches + the free-text "distinguishing traits" field.
class CollarMarkerWidget extends ConsumerWidget {
  const CollarMarkerWidget({super.key, required this.traitsController});

  final TextEditingController traitsController;

  static const List<Map<String, String>> _availableColors = [
    {"name": "Golden", "hex": "#D4AF37"},
    {"name": "Black", "hex": "#000000"},
    {"name": "White", "hex": "#FFFFFF"},
    {"name": "Brown", "hex": "#8B4513"},
    {"name": "Gray", "hex": "#808080"},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColorHex = ref.watch(
      lostPetPostFormProvider.select((state) => state.primaryColorHex),
    );
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRIMARY COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _availableColors.map((c) {
              final isSelected = primaryColorHex == c["hex"];
              return GestureDetector(
                onTap: () => notifier.updateColor(c["hex"]!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(int.parse(c["hex"]!.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'DISTINGUISHING TRAITS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: traitsController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "e.g., White patch on chest, friendly",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => notifier.updateTraits(value),
          ),
        ],
      ),
    );
  }
}
