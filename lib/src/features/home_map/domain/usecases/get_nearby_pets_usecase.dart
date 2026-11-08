import '../entities/missing_pet_entity.dart';
import '../../data/repositories/missing_pet_repository_impl.dart';

/// Use case for fetching nearby missing pets
class GetNearbyPetsUseCase {
  final MissingPetRepositoryImpl _repository;

  GetNearbyPetsUseCase(this._repository);

  /// Execute the use case to fetch nearby missing pets
  Future<List<MissingPetEntity>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    return await _repository.getNearbyMissingPets(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Get a specific missing pet by ID
  Future<MissingPetEntity> getPetById(String petId) async {
    return await _repository.getMissingPet(petId);
  }
}
