import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pet_color_model.dart';
import '../../data/models/pet_pattern_model.dart';

/// State class for the report form
class ReportFormState {
  final String petName;
  final String? selectedSpecies;
  final PetColor? selectedColor;
  final PetPattern? selectedPattern;
  final String? size;
  final String? markings;
  final double bountyAmount;
  final String? imagePath;
  final bool isSubmitting;
  final String? errorMessage;

  const ReportFormState({
    this.petName = '',
    this.selectedSpecies,
    this.selectedColor,
    this.selectedPattern,
    this.size,
    this.markings,
    this.bountyAmount = 0,
    this.imagePath,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Check if the form has all required fields filled
  bool get isValid {
    return petName.isNotEmpty &&
        selectedSpecies != null &&
        imagePath != null &&
        bountyAmount > 0;
  }

  /// Copy with method for creating updated copies of the state
  ReportFormState copyWith({
    String? petName,
    String? selectedSpecies,
    PetColor? selectedColor,
    PetPattern? selectedPattern,
    String? size,
    String? markings,
    double? bountyAmount,
    String? imagePath,
    bool? isSubmitting,
    String? errorMessage,
    bool clearSelectedColor = false,
    bool clearSelectedPattern = false,
  }) {
    return ReportFormState(
      petName: petName ?? this.petName,
      selectedSpecies: selectedSpecies ?? this.selectedSpecies,
      selectedColor: clearSelectedColor ? null : (selectedColor ?? this.selectedColor),
      selectedPattern: clearSelectedPattern ? null : (selectedPattern ?? this.selectedPattern),
      size: size ?? this.size,
      markings: markings ?? this.markings,
      bountyAmount: bountyAmount ?? this.bountyAmount,
      imagePath: imagePath ?? this.imagePath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier class for managing the report form state
class ReportFormNotifier extends StateNotifier<ReportFormState> {
  ReportFormNotifier() : super(const ReportFormState());

  /// Update the pet name
  void updatePetName(String value) {
    state = state.copyWith(petName: value);
  }

  /// Update the species selection
  void updateSpecies(String? species) {
    state = state.copyWith(selectedSpecies: species);
  }

  /// Update the selected color
  void updateColor(PetColor? color) {
    state = state.copyWith(selectedColor: color);
  }

  /// Clear the selected color
  void clearColor() {
    state = state.copyWith(clearSelectedColor: true);
  }

  /// Update the selected pattern
  void updatePattern(PetPattern? pattern) {
    state = state.copyWith(selectedPattern: pattern);
  }

  /// Clear the selected pattern
  void clearPattern() {
    state = state.copyWith(clearSelectedPattern: true);
  }

  /// Update the size
  void updateSize(String? size) {
    state = state.copyWith(size: size);
  }

  /// Update the markings
  void updateMarkings(String? markings) {
    state = state.copyWith(markings: markings);
  }

  /// Update the bounty amount
  void updateBountyAmount(double amount) {
    state = state.copyWith(bountyAmount: amount);
  }

  /// Update the image path
  void updateImagePath(String? path) {
    state = state.copyWith(imagePath: path);
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset the form to its initial state
  void reset() {
    state = const ReportFormState();
  }
}

/// Provider for the report form state
final reportFormProvider =
    StateNotifierProvider<ReportFormNotifier, ReportFormState>((ref) {
  return ReportFormNotifier();
});
