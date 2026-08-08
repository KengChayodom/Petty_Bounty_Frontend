import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lost_pet_post_repository.dart';
import '../data/models/lost_pet_post_request.dart';
import '../domain/providers/lost_pet_post_form_provider.dart';
import 'widgets/bounty_section_widget.dart';
import 'widgets/collar_marker_widget.dart';
import 'widgets/location_tile_widget.dart';
import 'widgets/last_seen_time_widget.dart';
import 'widgets/photo_picker_widget.dart';
import 'widgets/species_selector_widget.dart';

class LostPetPostScreen extends ConsumerStatefulWidget {
  const LostPetPostScreen({super.key});

  @override
  ConsumerState<LostPetPostScreen> createState() => _LostPetPostScreenState();
}

class _LostPetPostScreenState extends ConsumerState<LostPetPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _traitsController = TextEditingController();
  final TextEditingController _bountyInputController = TextEditingController(
    text: '10000',
  );

  // True while the photo is being uploaded as part of submit — blocks a
  // double-tap from firing a second upload for the same report.
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _traitsController.dispose();
    _bountyInputController.dispose();
    super.dispose();
  }

  // ฟังก์ชันส่งข้อมูลไปยัง Backend
  Future<void> _submitReport() async {
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(lostPetPostFormProvider);

    if (formState.imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a pet photo first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (formState.latitude == null || formState.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set the last seen location first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    // The photo picker already uploads on pick (for the species-detection
    // call) and stores the URL — reuse it instead of uploading again.
    String imageUrl;
    if (formState.imageUrl != null) {
      imageUrl = formState.imageUrl!;
    } else {
      try {
        imageUrl = await ref
            .read(lostPetPostRepositoryProvider)
            .uploadImage(formState.imagePath!);
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    // สร้าง request ให้ตรงกับ MissingPetCreate Schema เป๊ะๆ
    final request = LostPetPostRequest(
      petName: formState.petName.trim(),
      species: formState.species, // Cat, Dog, Bird, Other
      characteristics: {
        "color": formState.primaryColorHex,
        "traits": formState.traits.trim().isNotEmpty
            ? formState.traits.trim()
            : "Standard",
      },
      bountyAmount: formState.isBountyMode ? formState.bountyAmount : 0.0,
      latitude: formState.latitude!,
      longitude: formState.longitude!,
      lastSeenTime: formState.lastSeenTime,
      imageUrl: imageUrl,
      primaryColorHex: formState.primaryColorHex,
    );

    try {
      await ref.read(lostPetPostRepositoryProvider).createLostPetPost(request);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Keep the form filled in on failure — the user shouldn't have to
      // redo everything just to retry.
      return;
    }

    if (!mounted) return;
    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcasting missing pet case...')),
    );

    // Clear the form so a stale photo/location/bounty from this post
    // can't silently carry into the next one.
    ref.read(lostPetPostFormProvider.notifier).reset();
    _nameController.clear();
    _traitsController.clear();
    _bountyInputController.text = '10000';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CREATE POSTER',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ส่วนอัปโหลดรูปภาพ
              const PhotoPickerWidget(),
              const SizedBox(height: 16),

              // 1.1 เลือกชนิดสัตว์เลี้ยง
              const SpeciesSelectorWidget(),
              const SizedBox(height: 16),

              // 2. ช่องกรอกชื่อสัตว์เลี้ยง (Pet's Name)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.text_fields,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: "Pet's Name ...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onChanged: (value) => notifier.updatePetName(value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter pet name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Collar Marker & Pattern Selector & Traits
              CollarMarkerWidget(traitsController: _traitsController),
              const SizedBox(height: 16),

              // 4. ช่องระบุสถานที่
              const LocationTileWidget(),
              const SizedBox(height: 12),

              // 5. ช่องระบุเวลา
              const LastSeenTimeWidget(),
              const SizedBox(height: 16),

              // 6-8. Help Type Toggle + Reward info + Bounty amount
              BountySectionWidget(bountyController: _bountyInputController),
              const SizedBox(height: 24),

              // 9. ปุ่มยืนยันส่งข้อมูลหลัก (Broadcast Case Button)
              ElevatedButton(
                onPressed: _isUploading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0022FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'BROADCAST CASE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
