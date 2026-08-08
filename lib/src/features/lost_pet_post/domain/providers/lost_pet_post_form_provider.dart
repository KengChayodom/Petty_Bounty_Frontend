import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the "Post Lost Pet" (Broadcast Case) form.
class LostPetPostFormState {
  final String petName;
  final String species;
  final String? primaryColorHex;
  final String traits;
  final bool isBountyMode;
  final double bountyAmount;
  final String? imagePath;
  // The uploaded photo's public URL, set as soon as picking finishes (so the
  // AI-analyze call has something to hit) and reused at submit time to avoid
  // uploading the same photo twice.
  final String? imageUrl;
  // Deliberately nullable (no fallback default): unlike a placeholder value,
  // null lets the UI/submit flow tell "location not set yet" apart from "set
  // to some coordinate" without a fragile double comparison.
  final double? latitude;
  final double? longitude;
  final DateTime lastSeenTime;

  const LostPetPostFormState({
    this.petName = '',
    this.species = 'Dog',
    this.primaryColorHex = '#D4AF37',
    this.traits = '',
    this.isBountyMode = false,
    this.bountyAmount = 10000.0,
    this.imagePath,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.lastSeenTime,
  });

  LostPetPostFormState copyWith({
    String? petName,
    String? species,
    String? primaryColorHex,
    String? traits,
    bool? isBountyMode,
    double? bountyAmount,
    String? imagePath,
    String? imageUrl,
    double? latitude,
    double? longitude,
    DateTime? lastSeenTime,
    bool clearPrimaryColorHex = false,
    bool clearImagePath = false,
    bool clearImageUrl = false,
  }) {
    return LostPetPostFormState(
      petName: petName ?? this.petName,
      species: species ?? this.species,
      primaryColorHex: clearPrimaryColorHex
          ? null
          : (primaryColorHex ?? this.primaryColorHex),
      traits: traits ?? this.traits,
      isBountyMode: isBountyMode ?? this.isBountyMode,
      bountyAmount: bountyAmount ?? this.bountyAmount,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeenTime: lastSeenTime ?? this.lastSeenTime,
    );
  }
}

class LostPetPostFormNotifier extends StateNotifier<LostPetPostFormState> {
  LostPetPostFormNotifier()
      : super(LostPetPostFormState(lastSeenTime: DateTime.now()));

  void updatePetName(String value) => state = state.copyWith(petName: value);

  void updateSpecies(String value) => state = state.copyWith(species: value);

  void updateColor(String hex) =>
      state = state.copyWith(primaryColorHex: hex);

  void updateTraits(String value) => state = state.copyWith(traits: value);

  void updateBountyMode(bool isBountyMode) =>
      state = state.copyWith(isBountyMode: isBountyMode);

  void updateImagePath(String path) =>
      state = state.copyWith(imagePath: path);

  void updateImageUrl(String url) => state = state.copyWith(imageUrl: url);

  /// Clears the picked photo (local path + uploaded URL) back to null, e.g.
  /// the file became unreadable or the user needs to re-pick.
  void clearImage() =>
      state = state.copyWith(clearImagePath: true, clearImageUrl: true);

  /// Clears the selected color back to null.
  void clearColor() => state = state.copyWith(clearPrimaryColorHex: true);

  void updateLocation(double latitude, double longitude) => state =
      state.copyWith(latitude: latitude, longitude: longitude);

  void updateLastSeenTime(DateTime dateTime) =>
      state = state.copyWith(lastSeenTime: dateTime);

  void updateBountyAmount(double amount) =>
      state = state.copyWith(bountyAmount: amount);

  /// Adds [amount] on top of the current bounty (the "+1,000 / +5,000 /
  /// +10,000" quick-add chips) and returns the new total, so the caller can
  /// mirror it into the bounty TextField's controller.
  double addBounty(double amount) {
    final updated = state.bountyAmount + amount;
    state = state.copyWith(bountyAmount: updated);
    return updated;
  }

  /// Reset the form to its initial state (e.g. after a successful submit).
  void reset() {
    state = LostPetPostFormState(lastSeenTime: DateTime.now());
  }
}

/// `autoDispose`: this form's state belongs to a single screen visit — it
/// must NOT survive after the user navigates away, otherwise a stale photo/
/// location/bounty from a previous post silently carries into the next one.
final lostPetPostFormProvider = StateNotifierProvider.autoDispose<
    LostPetPostFormNotifier, LostPetPostFormState>((ref) {
  return LostPetPostFormNotifier();
});
