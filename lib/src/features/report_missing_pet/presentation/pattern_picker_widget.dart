import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pet_pattern_model.dart';
import '../domain/providers/report_form_provider.dart';

/// Widget for selecting a pet's coat pattern
class PatternPickerWidget extends ConsumerWidget {
  const PatternPickerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPattern = ref.watch(
      reportFormProvider.select((state) => state.selectedPattern),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coat Pattern',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PetPattern.allPatterns.map((pattern) {
            final isSelected = selectedPattern?.id == pattern.id;
            return FilterChip(
              label: Text(pattern.name),
              selected: isSelected,
              onSelected: (_) {
                ref.read(reportFormProvider.notifier).updatePattern(
                  isSelected ? null : pattern,
                );
              },
              selectedColor: const Color(0xFFED7645).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFFED7645),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFED7645)
                    : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFFED7645)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        if (selectedPattern != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  selectedPattern.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
