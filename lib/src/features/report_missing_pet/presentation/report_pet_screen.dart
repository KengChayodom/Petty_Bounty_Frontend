import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petty_bounty/src/core/ui/snackbar_helpers.dart';
import '../../../core/ui/skeleton/skeleton.dart';
import '../domain/providers/report_form_provider.dart';
import 'color_picker_widget.dart';
import 'pattern_picker_widget.dart';

/// Screen for reporting a missing pet
class ReportPetScreen extends ConsumerStatefulWidget {
  const ReportPetScreen({super.key});

  @override
  ConsumerState<ReportPetScreen> createState() => _ReportPetScreenState();
}

class _ReportPetScreenState extends ConsumerState<ReportPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bountyController = TextEditingController();
  final _markingsController = TextEditingController();
  final _speciesOptions = const ['Cat', 'Dog', 'Bird', 'Other'];
  final _sizeOptions = const ['Small', 'Medium', 'Large'];

  @override
  void dispose() {
    _bountyController.dispose();
    _markingsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // TODO: Implement image picker
    // For now, just show a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker will be implemented here'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(reportFormProvider);
    if (!formState.isValid) {
      if (mounted) {
        context.showErrorSnackBar('Please fill in all required fields');
      }
      return;
    }

    // TODO: Implement API call to submit report
    if (mounted) {
      context.showSuccessSnackBar('Report submitted successfully!');
      // Reset form
      ref.read(reportFormProvider.notifier).reset();
      _bountyController.clear();
      _markingsController.clear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reportFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Missing Pet'),
        backgroundColor: const Color(0xFFED7645),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pet Photo Section
            _buildPhotoSection(formState),
            const SizedBox(height: 24),

            // Pet Name
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Pet Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
              onChanged: (value) {
                ref.read(reportFormProvider.notifier).updatePetName(value);
              },
            ),
            const SizedBox(height: 16),

            // Species Selector
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Species *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cruelty_free),
              ),
              items: _speciesOptions
                  .map((species) => DropdownMenuItem(
                        value: species,
                        child: Text(species),
                      ))
                  .toList(),
              validator: (value) => value == null ? 'Required' : null,
              onChanged: (value) {
                ref.read(reportFormProvider.notifier).updateSpecies(value);
              },
            ),
            const SizedBox(height: 24),

            // Color Picker
            const ColorPickerWidget(),
            const SizedBox(height: 24),

            // Pattern Picker
            const PatternPickerWidget(),
            const SizedBox(height: 24),

            // Size Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Size',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              items: _sizeOptions
                  .map((size) => DropdownMenuItem(
                        value: size,
                        child: Text(size),
                      ))
                  .toList(),
              onChanged: (value) {
                ref.read(reportFormProvider.notifier).updateSize(value);
              },
            ),
            const SizedBox(height: 16),

            // Markings
            TextFormField(
              controller: _markingsController,
              decoration: const InputDecoration(
                labelText: 'Distinct Markings (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 2,
              onChanged: (value) {
                ref.read(reportFormProvider.notifier).updateMarkings(value);
              },
            ),
            const SizedBox(height: 16),

            // Bounty Amount
            TextFormField(
              controller: _bountyController,
              decoration: const InputDecoration(
                labelText: 'Bounty Amount *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (double.tryParse(value!) == null) return 'Invalid amount';
                return null;
              },
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                ref.read(reportFormProvider.notifier).updateBountyAmount(amount);
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            if (formState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  formState.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            ElevatedButton(
              onPressed: formState.isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED7645),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: formState.isSubmitting
                  ? const BusyButtonLabel(width: 118)
                  : const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ReportFormState formState) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: formState.imagePath != null
                ? const Color(0xFFED7645)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: formState.imagePath != null
            // TODO: Display selected image
            // For now, show placeholder even when image is selected
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photo selected',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add photo *',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Required for submission',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
