import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_config.dart';
import '../../data/lost_pet_post_repository.dart';
import '../../domain/providers/lost_pet_post_form_provider.dart';

/// The four species options the backend accepts — shared with
/// [SpeciesSelectorWidget]'s chip row (kept in sync manually since the two
/// widgets are deliberately independent files).
const _speciesOptions = ['Cat', 'Dog', 'Bird'];

/// Photo picker box (gallery or camera). Once a photo is picked it's
/// uploaded immediately and sent to the same AI species-detection endpoint
/// the camera/sightings flow uses, then the detected species is offered to
/// the user via a confirm-or-correct dialog (mirrors
/// `sightings/presentation/verification_screen.dart`'s pattern).
class PhotoPickerWidget extends ConsumerStatefulWidget {
  const PhotoPickerWidget({super.key});

  @override
  ConsumerState<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends ConsumerState<PhotoPickerWidget> {
  // True while the photo is being uploaded + sent for AI species detection.
  bool _isAnalyzing = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // แสดง BottomSheet ให้เลือกระหว่างถ่ายรูป หรือเลือกจากคลังภาพ
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        // Ceiling only. This is the LOST-PET path, so the photo picked here
        // becomes the seed vector every future sighting is matched against —
        // see AppConfig.petImageMaxDimension before touching it.
        maxWidth: AppConfig.petImageMaxDimension.toDouble(),
        maxHeight: AppConfig.petImageMaxDimension.toDouble(),
      );
      if (image == null || !mounted) return;

      // Show the preview right away — species detection can fail/be slow,
      // and the user should keep their photo regardless.
      ref.read(lostPetPostFormProvider.notifier).updateImagePath(image.path);

      await _analyzeAndConfirmSpecies(image.path);
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeAndConfirmSpecies(String imagePath) async {
    setState(() => _isAnalyzing = true);
    final repository = ref.read(lostPetPostRepositoryProvider);

    String imageUrl;
    try {
      imageUrl = await repository.uploadImage(imagePath);
    } catch (e) {
      // No confirmed species without a successful upload — clear the photo
      // rather than leaving an unverified one sitting in the form.
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ref.read(lostPetPostFormProvider.notifier).clearImage();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    ref.read(lostPetPostFormProvider.notifier).updateImageUrl(imageUrl);

    Map<String, dynamic>? analysis;
    try {
      analysis = await repository.analyzeImage(imageUrl);
    } catch (_) {
      analysis = null;
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    final data = analysis?['data'] as Map<String, dynamic>?;
    final detectedSpecies = data?['species'] as String?;

    if (analysis != null &&
        analysis['status'] == 'success' &&
        detectedSpecies != null) {
      await _showConfirmationDialog(detectedSpecies);
    } else if (mounted) {
      // AI found no animal in the photo at all (or the analyze call itself
      // failed) — don't let an unverified photo sit in the form; the user
      // must retry with a different/clearer photo, same as the sightings
      // camera flow requires.
      ref.read(lostPetPostFormProvider.notifier).clearImage();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't detect a pet in that photo — please try a different one.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showConfirmationDialog(String detectedSpecies) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? selectedSpecies = detectedSpecies;
        bool showCorrectionView = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!showCorrectionView) {
              // Stage 1 — accept the AI's guess as-is, or say it's wrong.
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Image.file(
                        File(ref.read(lostPetPostFormProvider).imagePath!),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(text: 'Is this a '),
                          TextSpan(
                            text: detectedSpecies,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' ?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () {
                            ref
                                .read(lostPetPostFormProvider.notifier)
                                .updateSpecies(detectedSpecies);
                            ref
                                .read(lostPetPostFormProvider.notifier)
                                .confirmPhoto();
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => setDialogState(() {
                            showCorrectionView = true;
                            selectedSpecies = null;
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            // Stage 2 — pick the correct species by hand.
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.smart_toy, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI detected: $detectedSpecies',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedSpecies,
                    hint: const Text('Select species'),
                    items: _speciesOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedSpecies = val),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Submitting an incorrect species is considered '
                      'interference and may result in a penalty if flagged '
                      'by an admin.',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(lostPetPostFormProvider.notifier).clearImage();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedSpecies == null
                      ? null
                      : () {
                          ref
                              .read(lostPetPostFormProvider.notifier)
                              .updateSpecies(selectedSpecies!);
                          ref
                              .read(lostPetPostFormProvider.notifier)
                              .confirmPhoto();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = ref.watch(
      lostPetPostFormProvider.select((state) => state.imagePath),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PET PHOTO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isAnalyzing ? null : _pickImage,
          child: Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: imagePath != null ? Colors.blue : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  image: imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(imagePath)),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // The picked file can go stale (e.g. OS reclaims a
                            // temp/cache path) — fall back to the "add photo"
                            // placeholder instead of a broken image.
                            if (!mounted) return;
                            ref
                                .read(lostPetPostFormProvider.notifier)
                                .clearImage();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'That photo could not be loaded — please pick it again.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        )
                      : null,
                ),
                child: imagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'TAP TO ADD PHOTO',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              if (imagePath != null && !_isAnalyzing)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (_isAnalyzing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'AI is analyzing...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
