import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/providers/profile_providers.dart';

/// Modal dialog allowing user to edit Username (display_name) & Profile Picture.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({
    super.key,
    required this.currentDisplayName,
    required this.currentPhotoUrl,
    required this.onSave,
  });

  final String currentDisplayName;
  final String? currentPhotoUrl;

  /// Returns true on success, false on failure — the dialog only closes
  /// itself on true, so a failed save doesn't silently look like it worked.
  final Future<bool> Function(String newDisplayName, String? newPhotoUrl) onSave;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  // The photo URL that will actually be sent on save — starts as the
  // current one, replaced once a newly-picked photo finishes uploading.
  String? _photoUrl;
  String? _localPreviewPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentDisplayName);
    _photoUrl = widget.currentPhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;

    setState(() {
      _localPreviewPath = image.path;
      _isUploadingPhoto = true;
    });

    try {
      final url =
          await ref.read(profileRepositoryProvider).uploadPhoto(image.path);
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingPhoto = false;
        _localPreviewPath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    // Wait for the real result before deciding whether to close — closing
    // unconditionally right after firing this off would show a "successful"
    // dialog dismissal even when the save actually failed.
    final success = await widget.onSave(name, _photoUrl);
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop();
    }
    // On failure the dialog stays open with the typed name and picked photo
    // intact, so the user can just retry instead of redoing everything.
  }

  ImageProvider? _avatarImage() {
    if (_localPreviewPath != null) return FileImage(File(_localPreviewPath!));
    if (_photoUrl != null) return NetworkImage(_photoUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _avatarImage();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: Color(0xFF0022FF)),
          SizedBox(width: 8),
          Text(
            'EDIT PROFILE',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                          : null,
                    ),
                    if (_isUploadingPhoto)
                      const Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0022FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Username / Display Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Hunter Guide',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isSaving || _isUploadingPhoto) ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0022FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
