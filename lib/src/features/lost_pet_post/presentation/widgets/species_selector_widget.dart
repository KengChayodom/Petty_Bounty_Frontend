import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/pet_species.dart';
import '../../domain/providers/lost_pet_post_form_provider.dart';

/// Species chip row (Cat/Dog/Bird/Other) — required by the backend schema.
class SpeciesSelectorWidget extends ConsumerWidget {
  const SpeciesSelectorWidget({super.key});

  static List<String> get _species => PetSpecies.labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      lostPetPostFormProvider.select((state) => state.species),
    );
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SPECIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
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
        ),
      ],
    );
  }
}
