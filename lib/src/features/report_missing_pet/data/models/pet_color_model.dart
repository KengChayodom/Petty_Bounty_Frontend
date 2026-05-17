/// Model for pet coat colors
class PetColor {
  final String name;
  final String hexCode;
  final String id;

  const PetColor({
    required this.name,
    required this.hexCode,
    required this.id,
  });

  /// List of all available pet colors
  static const List<PetColor> allColors = [
    PetColor(name: 'Black', hexCode: '#000000', id: 'black'),
    PetColor(name: 'White', hexCode: '#FFFFFF', id: 'white'),
    PetColor(name: 'Brown', hexCode: '#5D4037', id: 'brown'),
    PetColor(name: 'Gray', hexCode: '#9E9E9E', id: 'gray'),
    PetColor(name: 'Orange', hexCode: '#FF9800', id: 'orange'),
    PetColor(name: 'Cream', hexCode: '#FFF8E1', id: 'cream'),
    PetColor(name: 'Golden', hexCode: '#FFD700', id: 'golden'),
    PetColor(name: 'Tan', hexCode: '#D2B48C', id: 'tan'),
    PetColor(name: 'Chocolate', hexCode: '#3E2723', id: 'chocolate'),
    PetColor(name: 'Silver', hexCode: '#C0C0C0', id: 'silver'),
    PetColor(name: 'Blue/Gray', hexCode: '#1976D2', id: 'blue'),
    PetColor(name: 'Red', hexCode: '#D32F2F', id: 'red'),
  ];

  /// Find a color by its ID
  static PetColor? findById(String id) {
    for (final color in allColors) {
      if (color.id == id) return color;
    }
    return null;
  }
}
