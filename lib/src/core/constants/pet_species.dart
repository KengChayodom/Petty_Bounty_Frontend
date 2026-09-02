/// Centralized Pet Species enum and constants across Petty Bounty.
enum PetSpecies {
  cat('Cat', '🐱'),
  dog('Dog', '🐶'),
  bird('Bird', '🦜');

  final String label;
  final String emoji;

  const PetSpecies(this.label, this.emoji);

  /// List of selectable species labels ['Cat', 'Dog', 'Bird'].
  static List<String> get labels =>
      PetSpecies.values.map((e) => e.label).toList();

  /// Parse from string, returning null when the value is not one of
  /// Cat / Dog / Bird (e.g. a legacy 'Other' record or a raw AI detection
  /// like 'Rabbit'). Callers decide how to present an unmatched value.
  static PetSpecies? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final species in PetSpecies.values) {
      if (species.label.toLowerCase() == normalized) return species;
    }
    return null;
  }

  /// Get emoji by species name string, falling back to a neutral paw for
  /// any value outside Cat / Dog / Bird.
  static String emojiFor(String? speciesName) {
    return fromString(speciesName)?.emoji ?? '🐾';
  }
}
