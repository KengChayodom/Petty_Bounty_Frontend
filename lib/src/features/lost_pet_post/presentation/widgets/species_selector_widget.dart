import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';

/// Species chip row (Cat/Dog/Bird/Other) — required by the backend schema.
class SpeciesSelectorWidget extends ConsumerWidget {
  const SpeciesSelectorWidget({super.key});

  static const _species = ['Dog', 'Cat', 'Bird', 'Other'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      lostPetPostFormProvider.select((state) => state.species),
    );
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    return Row(
      children: _species.map((s) {
        final isSelected = selected == s;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Center(child: Text(s)),
              selected: isSelected,
              onSelected: (_) => notifier.updateSpecies(s),
              selectedColor: Colors.blue[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[800] : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
