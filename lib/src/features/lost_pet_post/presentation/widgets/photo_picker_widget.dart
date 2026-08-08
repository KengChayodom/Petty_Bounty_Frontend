import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';

/// Photo picker box (gallery or camera) — shows a live preview once picked.
class PhotoPickerWidget extends ConsumerWidget {
  const PhotoPickerWidget({super.key});

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
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

    if (source == null || !context.mounted) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null && context.mounted) {
        ref.read(lostPetPostFormProvider.notifier).updateImagePath(image.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = ref.watch(
      lostPetPostFormProvider.select((state) => state.imagePath),
    );

    return GestureDetector(
      onTap: () => _pickImage(context, ref),
      child: Container(
        height: 180,
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
                    if (!context.mounted) return;
                    ref
                        .read(lostPetPostFormProvider.notifier)
                        .clearImagePath();
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
                  Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'ADD CREATE POSTER',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
