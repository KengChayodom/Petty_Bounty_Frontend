import 'package:flutter/material.dart';

import 'pet_detail_resolver.dart';
import 'pet_detail_view.dart';

/// Full-page presentation of the pet detail — the deep-link target opened when
/// a Bounty Hunter taps an FCM "missing pet nearby" notification.
///
/// Renders the SAME shared [PetDetailView] as the map bottom sheet (no
/// duplicate UI). Data is resolved by [PetDetailResolver]: used from memory if
/// the pet is already loaded, otherwise fetched by id (the usual deep-link
/// case, where only a petId is known).
class MissingPetDetailScreen extends StatelessWidget {
  const MissingPetDetailScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missing Pet')),
      body: PetDetailResolver(
        petId: petId,
        builder: (context, pet) => PetDetailView(pet: pet),
      ),
    );
  }
}
