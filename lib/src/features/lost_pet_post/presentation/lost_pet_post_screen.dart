import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

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

  // GlobalKeys for auto-scrolling to each of the 5 section cards
  final List<GlobalKey> _stepKeys = List.generate(5, (_) => GlobalKey());

  // Tracks the highest unlocked step index (0: Photo, 1: Species/Name, 2: Color/Traits, 3: Location/Time, 4: Reward)
  int _lastUnlockedStep = 0;

  // True while the photo is being uploaded as part of submit
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _traitsController.dispose();
    _bountyInputController.dispose();
    super.dispose();
  }

  void _updateUnlockedSteps(LostPetPostFormState formState) {
    int maxUnlocked = 0;

    // Step 0 (Photo) is done if imagePath & imageUrl exist AND species photo confirmation is complete
    if (formState.imagePath != null &&
        formState.imageUrl != null &&
        formState.isPhotoConfirmed) {
      maxUnlocked = 1;

      // Step 1 (Species, Name & Characteristics) is done if petName is not empty
      if (formState.petName.trim().isNotEmpty) {
        maxUnlocked = 2;

        // Step 2 (Location & Time) is done if location is picked
        if (formState.latitude != null && formState.longitude != null) {
          maxUnlocked = 3;
        }
      }
    }

    if (maxUnlocked > _lastUnlockedStep) {
      setState(() {
        _lastUnlockedStep = maxUnlocked;
      });
    }
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

    // Show modal loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF0022FF),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Broadcasting missing pet report...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Please wait while AI processes your poster',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

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
          Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
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

    final request = LostPetPostRequest(
      petName: formState.petName.trim(),
      species: formState.species,
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

    String? newPetId;
    try {
      newPetId = await ref
          .read(lostPetPostRepositoryProvider)
          .createLostPetPost(request);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final postedLat = formState.latitude;
    final postedLng = formState.longitude;

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

    setState(() {
      _isUploading = false;
      _lastUnlockedStep = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcasting missing pet case...')),
    );

    ref.read(lostPetPostFormProvider.notifier).reset();
    _nameController.clear();
    _traitsController.clear();
    _bountyInputController.text = '10000';

    if (postedLat != null && postedLng != null) {
      Navigator.of(context).pop<Map<String, dynamic>>({
        'location': LatLng(postedLat, postedLng),
        'petId': newPetId,
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSectionCard({
    required int stepIndex,
    required String stepNumber,
    required String title,
    required IconData icon,
    required Widget child,
    required bool isUnlocked,
    required bool isCompleted,
  }) {
    final bool isCurrentActive = isUnlocked && !isCompleted && (stepIndex == _lastUnlockedStep);

    Color borderColor = Colors.grey.shade200;
    Color badgeBg = const Color(0xFF0022FF).withValues(alpha: 0.1);
    Color badgeText = const Color(0xFF0022FF);
    IconData badgeIcon = icon;
    String badgeLabel = 'STEP $stepNumber';

    if (!isUnlocked) {
      borderColor = Colors.grey.shade200;
      badgeBg = Colors.grey.shade100;
      badgeText = Colors.grey.shade500;
      badgeIcon = Icons.lock_outline_rounded;
      badgeLabel = 'LOCKED';
    } else if (isCompleted) {
      borderColor = Colors.green.shade300;
      badgeBg = Colors.green.shade50;
      badgeText = Colors.green.shade700;
      badgeIcon = Icons.check_circle_rounded;
      badgeLabel = '';
    } else if (isCurrentActive) {
      borderColor = const Color(0xFF0022FF);
      badgeBg = const Color(0xFF0022FF);
      badgeText = Colors.white;
      badgeIcon = Icons.arrow_circle_right_rounded;
      badgeLabel = 'ACTIVE';
    }

    final cardWidget = Container(
      key: _stepKeys[stepIndex],
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isCurrentActive ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentActive
                ? const Color(0xFF0022FF).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isCurrentActive ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: badgeLabel.isEmpty ? 6 : 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeText),
                    if (badgeLabel.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeText,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isUnlocked ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );

    if (!isUnlocked) {
      return IgnorePointer(
        ignoring: true,
        child: Opacity(
          opacity: 0.45,
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(lostPetPostFormProvider);
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    // Auto-check and advance steps on state changes
    ref.listen<LostPetPostFormState>(lostPetPostFormProvider, (previous, next) {
      _updateUnlockedSteps(next);
    });

    final bool isStep0Done = formState.imagePath != null &&
        formState.imageUrl != null &&
        formState.isPhotoConfirmed;
    final bool isStep1Done = isStep0Done && formState.petName.trim().isNotEmpty;
    final bool isStep2Done = isStep1Done && (formState.latitude != null && formState.longitude != null);
    final bool isStep3Done = isStep2Done;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
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
                // Section 1: Pet Photo (Step 0)
                _buildSectionCard(
                  stepIndex: 0,
                  stepNumber: '1',
                  title: 'PET PHOTO',
                  icon: Icons.add_a_photo_outlined,
                  isUnlocked: true,
                  isCompleted: isStep0Done,
                  child: const PhotoPickerWidget(),
                ),

                // Section 2: Pet Details & Characteristics (Step 1 - Combined)
                _buildSectionCard(
                  stepIndex: 1,
                  stepNumber: '2',
                  title: 'DETAILS & CHARACTERISTICS',
                  icon: Icons.pets_outlined,
                  isUnlocked: 1 <= _lastUnlockedStep,
                  isCompleted: isStep1Done,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SpeciesSelectorWidget(),
                      const SizedBox(height: 16),
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
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: "Pet's Name ...",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                onChanged: (value) {
                                  notifier.updatePetName(value);
                                  _updateUnlockedSteps(ref.read(lostPetPostFormProvider));
                                },
                                onFieldSubmitted: (_) {
                                  _updateUnlockedSteps(ref.read(lostPetPostFormProvider));
                                },
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
                      CollarMarkerWidget(traitsController: _traitsController),
                    ],
                  ),
                ),

                // Section 3: Location & Time (Step 2)
                _buildSectionCard(
                  stepIndex: 2,
                  stepNumber: '3',
                  title: 'LOCATION & TIME',
                  icon: Icons.location_on_outlined,
                  isUnlocked: 2 <= _lastUnlockedStep,
                  isCompleted: isStep2Done,
                  child: const Column(
                    children: [
                      LocationTileWidget(),
                      SizedBox(height: 12),
                      LastSeenTimeWidget(),
                    ],
                  ),
                ),

                // Section 4: Reward / Bounty (Step 3)
                _buildSectionCard(
                  stepIndex: 3,
                  stepNumber: '4',
                  title: 'BOUNTY & REWARD',
                  icon: Icons.card_giftcard_outlined,
                  isUnlocked: 3 <= _lastUnlockedStep,
                  isCompleted: isStep3Done,
                  child: BountySectionWidget(
                    bountyController: _bountyInputController,
                  ),
                ),

                const SizedBox(height: 8),

                // Submit Button
                ElevatedButton(
                  onPressed: (_isUploading || _lastUnlockedStep < 3)
                      ? null
                      : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0022FF),
                    disabledBackgroundColor: Colors.grey.shade300,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: _lastUnlockedStep < 3 ? Colors.grey : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'BROADCAST CASE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: _lastUnlockedStep < 3 ? Colors.grey : Colors.white,
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
      ),
    );
  }
}
