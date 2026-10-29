import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/home_map/domain/entities/missing_pet_entity.dart';
import 'package:petty_bounty/src/features/home_map/domain/providers/nearby_pets_providers.dart';
import 'package:petty_bounty/src/features/home_map/domain/usecases/get_nearby_pets_usecase.dart';

class _PendingPets implements GetNearbyPetsUseCase {
  final result = Completer<List<MissingPetEntity>>();

  @override
  Future<List<MissingPetEntity>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) => result.future;

  @override
  Future<MissingPetEntity> getPetById(String petId) =>
      throw UnimplementedError();
}

void main() {
  for (final fails in [false, true]) {
    test(
      'ignores late ${fails ? 'failure' : 'success'} after disposal',
      () async {
        final pending = _PendingPets();
        final notifier = NearbyPetsNotifier(pending);
        final request = notifier.fetchNearbyPets(
          latitude: 13.7,
          longitude: 100.5,
        );
        notifier.dispose();
        if (fails) {
          pending.result.completeError(StateError('request failed'));
        } else {
          pending.result.complete([]);
        }
        await expectLater(request, completes);
      },
    );
  }
}
