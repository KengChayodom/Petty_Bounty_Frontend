import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:petty_bounty/src/core/ui/snackbar_helpers.dart';
import '../data/sighting_repository.dart';
import '../domain/pending_upload.dart';
import '../domain/sighting_providers.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String imagePath;

  /// Targeted mode (pet-detail entry): when [targetPetId] is non-null the
  /// hunter is reporting this specific lost pet, so we SKIP AI analysis and
  /// matching and submit the sighting straight to that pet's owner. When null
  /// this is the discovery flow (home FAB) — analyze + confirm + match.
  final String? targetPetId;
  final String? targetSpecies;
  final String? targetPetName;

  /// An upload for [imagePath] that the camera screen already kicked off at
  /// the shutter press. When present this screen awaits it rather than
  /// starting a second one; when null it uploads the file itself.
  final PendingUpload? pendingUpload;

  const VerificationScreen({
    super.key,
    required this.imagePath,
    this.targetPetId,
    this.targetSpecies,
    this.targetPetName,
    this.pendingUpload,
  });

  bool get isTargeted => targetPetId != null;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _isLoading = true;
  String? _detectedSpecies;
  String? _errorMessage;
  String? _uploadedImageUrl;
  List<double>? _bbox;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    if (widget.isTargeted) {
      _processTargetedSighting();
    } else {
      _processAIAnalysis();
    }
  }

  /// Targeted path: no YOLO/CLIP, no matching. Upload the photo, ask a single
  /// confirm, then submit the sighting straight to the chosen pet's owner.
  /// The photo's Storage URL, awaiting the upload the camera screen started at
  /// the shutter press when there is one. Falls back to uploading here for
  /// callers that navigated straight to this screen without pre-starting one.
  Future<String> _resolveUploadedUrl() {
    final pending = widget.pendingUpload;
    if (pending != null) return pending.url;
    return ref.read(sightingRepositoryProvider).uploadImage(widget.imagePath);
  }

  Future<void> _processTargetedSighting() async {
    try {
      final String uploadedUrl = await _resolveUploadedUrl();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _uploadedImageUrl = uploadedUrl;
      });
      _showTargetedConfirmDialog();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Connection error. Ensure backend is running.";
        });
      }
    }
  }

  void _showTargetedConfirmDialog() {
    final petName = widget.targetPetName ?? 'this pet';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send sighting?'),
        content: Text(
          "Report this photo directly to $petName's owner as a sighting?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitTargetedSighting(dialogContext),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTargetedSighting(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _getCurrentLocation();
      _currentPosition = position;

      await ref.read(sightingNotifierProvider.notifier).createTargetedSighting(
        imageUrl: _uploadedImageUrl!,
        latitude: position.latitude,
        longitude: position.longitude,
        detectedSpecies: widget.targetSpecies ?? 'Other',
        targetPetId: widget.targetPetId!,
      );

      if (mounted) {
        context.showSuccessSnackBar('Sighting sent to the owner.');
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: $e";
      });
    }
  }

  Future<void> _processAIAnalysis() async {
    try {
      final repository = ref.read(sightingRepositoryProvider);

      final String uploadedUrl = await _resolveUploadedUrl();
      if (mounted) {
        setState(() {
          _uploadedImageUrl = uploadedUrl;
        });
      }

      final analysisResult = await repository.analyzeImage(uploadedUrl);
      if (!mounted) return;

      // The backend returns 200 with status:"not_found" and data:null when YOLO
      // finds no cat/dog/bird. Guard against that BEFORE dereferencing ['data'],
      // otherwise a null-deref throws and the user wrongly sees the connection
      // error below.
      final status = analysisResult['status'];
      final data = analysisResult['data'];
      if (status == 'not_found' || data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No target animal detected, please try again.";
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _detectedSpecies = data['species'];
        if (data['bbox'] != null) {
          _bbox = List<double>.from(
            (data['bbox'] as List).map((e) => e as double),
          );
        }
      });

      if (_detectedSpecies != null && _detectedSpecies != 'Unknown') {
        _showConfirmationDialog();
      } else {
        setState(() {
          _errorMessage = "No target animal detected, please try again.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Connection error. Ensure backend is running.";
        });
      }
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _showConfirmationDialog() {
    String? selectedSpecies = _detectedSpecies;
    final List<String> speciesList = ['Cat', 'Dog', 'Bird', 'Other'];
    bool showDropdown = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!showDropdown) ...[
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: FileImage(File(widget.imagePath)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFFED7645),
                              child: Icon(
                                Icons.question_mark,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black87,
                            fontFamily: 'serif',
                          ),
                          children: [
                            const TextSpan(text: "Is this a "),
                            TextSpan(
                              text: _detectedSpecies ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const TextSpan(text: " ?"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _confirmSpecies(_detectedSpecies!, context),
                            child: const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                showDropdown = true;
                                selectedSpecies = null;
                              });
                            },
                            child: const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (showDropdown) ...[
                      Row(
                        children: [
                          const Icon(Icons.smart_toy, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "AI detected: ${_detectedSpecies ?? 'Unknown'}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Select the correct species:"),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedSpecies != _detectedSpecies
                            ? selectedSpecies
                            : null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text("Select species"),
                        items: speciesList.map((species) {
                          return DropdownMenuItem(
                            value: species,
                            child: Text(species),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSpecies = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Please select carefully. Submitting incorrect species "
                                "is considered interference. Repeated violations may "
                                "result in a penalty score deduction if flagged by an admin.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.pop();
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedSpecies == null
                                ? null
                                : () => _confirmSpecies(
                                    selectedSpecies!,
                                    context,
                                  ),
                            child: const Text("Confirm"),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmSpecies(
    String species,
    BuildContext dialogContext,
  ) async {
    Navigator.of(dialogContext).pop();

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _getCurrentLocation();
      _currentPosition = position;

      final notifier = ref.read(sightingNotifierProvider.notifier);
      await notifier.createSightingWithMatch(
        imageUrl: _uploadedImageUrl!,
        latitude: position.latitude,
        longitude: position.longitude,
        detectedSpecies: species,
        bbox: _bbox,
      );

      if (mounted) {
        // ส่ง imagePath + พิกัดที่ถ่ายไปให้ matching-results เพื่อโชว์รูปเรา
        // และให้หน้า Final Review ปักหมุดตำแหน่ง sighting ได้
        context.pushNamed(
          'matching-results',
          extra: {
            'imagePath': widget.imagePath,
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(widget.imagePath), fit: BoxFit.cover),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "AI is analyzing...",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

          if (!_isLoading && _errorMessage != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
