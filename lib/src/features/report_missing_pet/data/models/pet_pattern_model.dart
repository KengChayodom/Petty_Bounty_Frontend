/// Model for pet coat patterns
class PetPattern {
  final String name;
  final String id;
  final String description;

  const PetPattern({
    required this.name,
    required this.id,
    required this.description,
  });

  /// List of all available pet patterns
  static const List<PetPattern> allPatterns = [
    PetPattern(
      name: 'Solid',
      id: 'solid',
      description: 'Single color throughout',
    ),
    PetPattern(
      name: 'Tabby',
      id: 'tabby',
      description: 'Striped or blotched pattern',
    ),
    PetPattern(
      name: 'Calico',
      id: 'calico',
      description: 'Three colors (white, orange, black)',
    ),
    PetPattern(
      name: 'Tuxedo',
      id: 'tuxedo',
      description: 'Black and white bicolor',
    ),
    PetPattern(
      name: 'Spotted',
      id: 'spotted',
      description: 'Spots or speckles',
    ),
    PetPattern(
      name: 'Striped',
      id: 'striped',
      description: 'Distinct stripes',
    ),
    PetPattern(
      name: 'Bicolor',
      id: 'bicolor',
      description: 'Two colors',
    ),
    PetPattern(
      name: 'Tricolor',
      id: 'tricolor',
      description: 'Three colors',
    ),
    PetPattern(
      name: 'Merle',
      id: 'merle',
      description: 'Mottled or patchy color',
    ),
    PetPattern(
      name: 'Brindle',
      id: 'brindle',
      description: 'Tiger-stripe pattern',
    ),
  ];

  /// Find a pattern by its ID
  static PetPattern? findById(String id) {
    for (final pattern in allPatterns) {
      if (pattern.id == id) return pattern;
    }
    return null;
  }
}
