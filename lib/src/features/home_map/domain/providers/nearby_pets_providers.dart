import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/missing_pet_entity.dart';
import '../usecases/get_nearby_pets_usecase.dart';
import '../../data/repositories/missing_pet_repository_impl.dart';

// Repository provider
final missingPetRepositoryProvider = Provider<MissingPetRepositoryImpl>((ref) {
  return MissingPetRepositoryImpl();
});

// Use case provider
final getNearbyPetsUseCaseProvider = Provider<GetNearbyPetsUseCase>((ref) {
  final repository = ref.watch(missingPetRepositoryProvider);
  return GetNearbyPetsUseCase(repository);
});

// State for nearby pets
class NearbyPetsState {
  final bool isLoading;
  final List<MissingPetEntity> pets;
  final String? errorMessage;
  final double? currentLatitude;
  final double? currentLongitude;

  const NearbyPetsState({
    this.isLoading = false,
    this.pets = const [],
    this.errorMessage,
    this.currentLatitude,
    this.currentLongitude,
  });

  NearbyPetsState copyWith({
    bool? isLoading,
    List<MissingPetEntity>? pets,
    String? errorMessage,
    double? currentLatitude,
    double? currentLongitude,
  }) {
    return NearbyPetsState(
      isLoading: isLoading ?? this.isLoading,
      pets: pets ?? this.pets,
      errorMessage: errorMessage,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
    );
  }
}

// Notifier for nearby pets state
class NearbyPetsNotifier extends StateNotifier<NearbyPetsState> {
  final GetNearbyPetsUseCase _useCase;

  NearbyPetsNotifier(this._useCase) : super(const NearbyPetsState());

  /// Fetch nearby missing pets
  Future<void> fetchNearbyPets({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentLatitude: latitude,
      currentLongitude: longitude,
    );

    try {
      final pets = await _useCase(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      state = state.copyWith(
        isLoading: false,
        pets: pets,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refresh pets
  Future<void> refresh() async {
    if (state.currentLatitude != null && state.currentLongitude != null) {
      await fetchNearbyPets(
        latitude: state.currentLatitude!,
        longitude: state.currentLongitude!,
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Nearby pets state provider
final nearbyPetsProvider =
    StateNotifierProvider<NearbyPetsNotifier, NearbyPetsState>((ref) {
  final useCase = ref.watch(getNearbyPetsUseCaseProvider);
  return NearbyPetsNotifier(useCase);
});

// Selected pet ID provider (for bottom sheet)
final selectedPetIdProvider = StateProvider<String?>((ref) => null);
