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

  /// Submit the user-confirmed sighting and surface matches in one call.
  ///
  /// The backend's optimised 2-step pipeline already runs the pgvector
  /// match RPC inside `POST /sightings/` and bundles the result in the
  /// response, so we no longer need a separate `getMatches` HTTP call
  /// on the hot path. The `bbox` parameter is accepted but ignored —
  /// kept on the signature so existing callers don't break.
  Future<void> createSightingWithMatch({
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String detectedSpecies,
    List<double>? bbox,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      state = state.copyWith(uploadedImageUrl: imageUrl);

      final result = await _repository.createSighting(
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        detectedSpecies: detectedSpecies,
      );

      state = state.copyWith(
        sighting: result.sighting,
        matches: result.matches,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
