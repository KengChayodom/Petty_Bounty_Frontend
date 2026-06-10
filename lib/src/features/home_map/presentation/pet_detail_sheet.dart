import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/providers/nearby_pets_providers.dart';
import 'pet_detail_resolver.dart';
import 'pet_detail_view.dart';

/// Bottom-sheet presentation of the pet detail — the map-pin entry point.
/// Keeps the draggable sheet UX; the rich UI lives in the shared
/// [PetDetailView] and the "in-memory else fetch" data rule in
/// [PetDetailResolver] (so a pet outside the loaded radius is fetched instead
/// of shown as "Unknown").
class PetDetailSheet extends ConsumerWidget {
  const PetDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPetId = ref.watch(selectedPetIdProvider);
    if (selectedPetId == null) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              PetDetailResolver(
                petId: selectedPetId,
                loadingBuilder: (_) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                builder: (context, pet) => PetDetailView(
                  pet: pet,
                  scrollController: scrollController,
                ),
              ),
              // Drag handle floated over the image (sheet-only chrome).
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
