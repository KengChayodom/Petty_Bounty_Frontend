import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pet_color_model.dart';
import '../domain/providers/report_form_provider.dart';

/// Widget for selecting a pet's primary color
class ColorPickerWidget extends ConsumerWidget {
  const ColorPickerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(
      reportFormProvider.select((state) => state.selectedColor),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Primary Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (selectedColor != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _parseColor(selectedColor.hexCode),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: PetColor.allColors.map((color) {
            final isSelected = selectedColor?.id == color.id;
            return GestureDetector(
              onTap: () {
                ref.read(reportFormProvider.notifier).updateColor(
                  isSelected ? null : color,
                );
              },
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _parseColor(color.hexCode),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFED7645)
                            : Colors.grey.shade300,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFED7645).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    color.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFED7645)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Parse hex color string to Color
  Color _parseColor(String hexColor) {
    final color = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$color', radix: 16));
  }
}
