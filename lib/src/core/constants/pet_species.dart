/// Centralized Pet Species enum and constants across Petty Bounty.
enum PetSpecies {
  cat('Cat', '🐱'),
  dog('Dog', '🐶'),
  bird('Bird', '🦜'),
  other('Other', '🐾');

  final String label;
  final String emoji;

  const PetSpecies(this.label, this.emoji);

  /// List of species labels ['Cat', 'Dog', 'Bird', 'Other']
  static List<String> get labels =>
      PetSpecies.values.map((e) => e.label).toList();

  /// Parse from string safely, defaulting to Other if not matched
  static PetSpecies fromString(String? value) {
    if (value == null) return PetSpecies.other;
    final normalized = value.trim().toLowerCase();
    return PetSpecies.values.firstWhere(
      (e) => e.label.toLowerCase() == normalized,
      orElse: () => PetSpecies.other,
    );
  }

  /// Get emoji by species name string
  static String emojiFor(String? speciesName) {
    return fromString(speciesName).emoji;
  }
}
