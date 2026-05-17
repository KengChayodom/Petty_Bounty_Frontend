import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/sighting_model.dart';
import '../data/models/match_model.dart';
import '../data/sighting_repository.dart';

/// State for sighting creation and matching
class SightingState {
  final bool isLoading;
  final String? errorMessage;
  final SightingModel? sighting;
  final List<MatchModel> matches;
  final String? uploadedImageUrl;

  const SightingState({
    this.isLoading = false,
    this.errorMessage,
    this.sighting,
    this.matches = const [],
    this.uploadedImageUrl,
  });

  SightingState copyWith({
    bool? isLoading,
    String? errorMessage,
    SightingModel? sighting,
    List<MatchModel>? matches,
    String? uploadedImageUrl,
  }) {
    return SightingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      sighting: sighting ?? this.sighting,
      matches: matches ?? this.matches,
      uploadedImageUrl: uploadedImageUrl ?? this.uploadedImageUrl,
    );
  }
}

/// StateNotifier for managing sighting creation and matching
class SightingNotifier extends StateNotifier<SightingState> {
  final SightingRepository _repository;

  SightingNotifier(this._repository) : super(const SightingState());

  /// Upload image and create sighting
  Future<void> createSightingWithMatch({
    required String imagePath,
    required double latitude,
    required double longitude,
    required String detectedSpecies,
    List<double>? bbox,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Step 1: Upload image
      final imageUrl = await _repository.uploadImage(imagePath);
      state = state.copyWith(uploadedImageUrl: imageUrl);

      // Step 2: Create sighting
      final sighting = await _repository.createSighting(
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        detectedSpecies: detectedSpecies,
        bbox: bbox,
      );
      state = state.copyWith(sighting: sighting);

      // Step 3: Get matches
      final matches = await _repository.getMatches(
        sightingId: sighting.id,
        limit: 5,
        radiusKm: 10.0,
      );
      state = state.copyWith(matches: matches, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const SightingState();
  }
}

/// Provider for SightingNotifier
final sightingNotifierProvider =
    StateNotifierProvider<SightingNotifier, SightingState>((ref) {
  final repository = ref.watch(sightingRepositoryProvider);
  return SightingNotifier(repository);
});
