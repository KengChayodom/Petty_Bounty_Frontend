import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/missing_pet_repository_impl.dart';
import '../domain/entities/missing_pet_entity.dart';
import '../domain/providers/nearby_pets_providers.dart';
import 'pet_detail_skeleton.dart';

/// Resolves a pet for the detail UI using ONE shared rule, used by both the
/// map bottom sheet and the push deep-link page:
///   * if the pet is already in [nearbyPetsProvider] (the map case), render it
///     immediately — no fetch, no flicker;
///   * otherwise (the deep-link case, or a pet outside the loaded radius),
///     fetch it by id from the backend.
///
/// This removes the old sheet's "Unknown" placeholder fragility — a pet not in
/// the in-memory list is fetched instead of shown as Unknown.
class PetDetailResolver extends ConsumerStatefulWidget {
  const PetDetailResolver({
    super.key,
    required this.petId,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String petId;
  final Widget Function(BuildContext context, MissingPetEntity pet) builder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  ConsumerState<PetDetailResolver> createState() => _PetDetailResolverState();
}

class _PetDetailResolverState extends ConsumerState<PetDetailResolver> {
  Future<MissingPetEntity>? _fetch;

  @override
  Widget build(BuildContext context) {
    // Prefer the in-memory entity. `watch` so a list that populates slightly
    // later (e.g. nearby still loading) resolves without a manual fetch.
    final pets = ref.watch(nearbyPetsProvider).pets;
    for (final p in pets) {
      if (p.id == widget.petId) return widget.builder(context, p);
    }

    // Not in memory → fetch by id exactly once.
    _fetch ??= MissingPetRepositoryImpl().getMissingPet(widget.petId);
    return FutureBuilder<MissingPetEntity>(
      future: _fetch,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingBuilder?.call(context) ??
              const PetDetailSkeleton();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final error = snapshot.error ?? 'Pet not found';
          return widget.errorBuilder?.call(context, error) ??
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load this pet.\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
        }
        return widget.builder(context, snapshot.data!);
      },
    );
  }
}
