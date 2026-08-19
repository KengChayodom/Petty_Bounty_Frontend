import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_config.dart';
import '../data/sighting_repository.dart';
import '../domain/pending_upload.dart';
import 'widgets/camera_skeletons.dart';

/// Outcome of trying to bring the camera up.
///
/// [unavailable] and [permissionDenied] are deliberately distinct: the first
/// means there is no camera hardware (typical on the iOS Simulator), the second
/// means a camera exists but the OS denied access. They get different fallback
/// UIs.
enum CameraSetupStatus { initializing, ready, unavailable, permissionDenied }

/// Result of [CameraInitializer]. [controller] is non-null only when
/// [status] == [CameraSetupStatus.ready].
class CameraSetupResult {
  const CameraSetupResult(this.status, {this.controller});

  final CameraSetupStatus status;
  final CameraController? controller;
}

/// Brings up the camera and reports the outcome. Injectable so widget tests can
/// drive the three branches without touching platform channels.
typedef CameraInitializer = Future<CameraSetupResult> Function();

/// Builds the live preview for a ready controller. Injectable so tests can
/// render the "ready" UI without a real platform-backed controller.
typedef CameraPreviewBuilder = Widget Function(CameraController controller);

class CameraScreen extends ConsumerStatefulWidget {
  /// When [targetPetId] is non-null the camera runs in TARGETED mode: the
  /// hunter is reporting this specific lost pet, so the verification screen
  /// skips AI analysis/matching and submits directly to the owner. When null
  /// it runs in DISCOVERY mode (home FAB) — analyze + match.
  const CameraScreen({
    super.key,
    this.targetPetId,
    this.targetSpecies,
    this.targetPetName,
    this.initializer,
    this.previewBuilder,
  });

  final String? targetPetId;
  final String? targetSpecies;
  final String? targetPetName;

  /// Test seam. Defaults to the real platform-backed initializer.
  final CameraInitializer? initializer;

  /// Test seam. Defaults to [CameraPreview].
  final CameraPreviewBuilder? previewBuilder;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _cameraController;
  CameraSetupStatus _status = CameraSetupStatus.initializing;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _runInitializer();
  }

  Future<void> _runInitializer() async {
    final result = await (widget.initializer ?? _defaultInitialize)();
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _cameraController = result.controller;
    });
  }

  /// Real platform initialization. Distinguishes "no camera" from "permission
  /// denied" so the UI can explain the right fix.
  Future<CameraSetupResult> _defaultInitialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        // No camera hardware (typical on the iOS Simulator).
        return const CameraSetupResult(CameraSetupStatus.unavailable);
      }

      final controller = CameraController(
        cameras[0],
        // veryHigh (1920x1080), NOT high (1280x720). The live-camera path
        // feeds the same CLIP matcher as the gallery path, but gallery photos
        // arrive at ~1536x2048 while `high` capped this one at 1280 on its
        // long side — the exact width at which a measured re-encode of the
        // seeded pets dropped one bird's self-similarity to 0.64 (its YOLO
        // mask collapsed to a 174x262 crop). Matching quality depends on
        // PIXELS ON THE ANIMAL, so a live capture must not arrive at a lower
        // resolution than the seed photos it is compared against.
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await controller.initialize();
      return CameraSetupResult(
        CameraSetupStatus.ready,
        controller: controller,
      );
    } on CameraException catch (e) {
      print('Error initializing camera: ${e.code} ${e.description}');
      // iOS: 'CameraAccessDenied' / 'CameraAccessDeniedWithoutPrompt'.
      // Android: 'cameraPermission'.
      final denied =
          e.code.contains('AccessDenied') ||
          e.code.toLowerCase().contains('permission');
      return CameraSetupResult(
        denied
            ? CameraSetupStatus.permissionDenied
            : CameraSetupStatus.unavailable,
      );
    } catch (e) {
      print('Error initializing camera: $e');
      return const CameraSetupResult(CameraSetupStatus.unavailable);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Bundle the captured image path with the (optional) targeted-mode fields
  /// so the verification screen knows which path to run.
  ///
  /// [upload] is the already-running upload for this photo — see
  /// [_startUpload]. The verification screen awaits it instead of starting its
  /// own, and falls back to uploading itself if it is null.
  Map<String, dynamic> _verificationArgs(
    String imagePath, {
    PendingUpload? upload,
  }) => {
    'imagePath': imagePath,
    'targetPetId': widget.targetPetId,
    'targetSpecies': widget.targetSpecies,
    'targetPetName': widget.targetPetName,
    'pendingUpload': upload,
  };

  /// Begin uploading the photo the instant we have it, WITHOUT awaiting.
  ///
  /// The upload has to finish before `/sightings/analyze` can run (that
  /// endpoint takes a URL), so it is on the critical path no matter what. What
  /// we can control is when it starts: doing it here overlaps the transfer with
  /// the route transition and the verification screen's first frame, and on the
  /// targeted path with the whole confirm dialog. By the time the user has
  /// finished reading, the photo is usually already in Storage.
  PendingUpload _startUpload(String imagePath) {
    return PendingUpload(
      ref.read(sightingRepositoryProvider).uploadImage(imagePath),
    );
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await controller.takePicture();
      if (mounted) {
        context.pushNamed(
          'verification',
          extra: _verificationArgs(
            photo.path,
            upload: _startUpload(photo.path),
          ),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        // Ceiling only — see AppConfig.petImageMaxDimension for why it must
        // not go below 2048 (CLIP matching reads the cropped animal).
        maxWidth: AppConfig.petImageMaxDimension.toDouble(),
        maxHeight: AppConfig.petImageMaxDimension.toDouble(),
      );

      if (photo != null && mounted) {
        context.pushNamed(
          'verification',
          extra: _verificationArgs(
            photo.path,
            upload: _startUpload(photo.path),
          ),
        );
      }
    } catch (e) {
      print('Error picking from gallery: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _backtohomepage() {
    if (mounted) {
      context.go('/');
    }
  }

  /// Bottom-left gallery button — shared by the live camera and the fallback
  /// screens so it sits in the same spot in all of them.
  Widget _galleryButton() {
    return GestureDetector(
      onTap: _pickFromGallery,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.photo_library, color: Colors.white),
      ),
    );
  }

  Widget _closeButton() {
    return Positioned(
      top: 50,
      left: 20,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 30),
        onPressed: _backtohomepage,
      ),
    );
  }

  /// Bottom bar that only holds the gallery button (used by both fallbacks so
  /// the gallery stays at the bottom-left exactly like the live camera).
  Widget _galleryOnlyBottomBar() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: _isProcessing
          ? const Center(child: CameraBusyBar())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [_galleryButton()],
              ),
            ),
    );
  }

  /// A centered icon + message used by both fallback screens.
  Widget _fallbackMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when there is no camera hardware (e.g. iOS Simulator).
  Widget _buildNoCameraScreen() {
    return Scaffold(
      key: const Key('camera_no_camera'),
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          _fallbackMessage(
            icon: Icons.no_photography,
            title: 'ไม่พบกล้อง',
            subtitle: 'เลือกรูปจากแกลเลอรี่แทนได้',
          ),
          _closeButton(),
          _galleryOnlyBottomBar(),
        ],
      ),
    );
  }

  /// Shown when a camera exists but the OS denied access.
  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      key: const Key('camera_permission_denied'),
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          _fallbackMessage(
            icon: Icons.lock_outline,
            title: 'ไม่ได้รับสิทธิ์ใช้กล้อง',
            subtitle: 'เปิดสิทธิ์กล้องในการตั้งค่า\nหรือเลือกรูปจากแกลเลอรี่แทน',
          ),
          _closeButton(),
          _galleryOnlyBottomBar(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case CameraSetupStatus.permissionDenied:
        return _buildPermissionDeniedScreen();
      case CameraSetupStatus.unavailable:
        return _buildNoCameraScreen();
      case CameraSetupStatus.initializing:
        return const CameraInitializingSkeleton();
      case CameraSetupStatus.ready:
        break;
    }

    final controller = _cameraController!;
    final preview = widget.previewBuilder != null
        ? widget.previewBuilder!(controller)
        : CameraPreview(controller);

    return Scaffold(
      key: const Key('camera_ready'),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: preview),

          _closeButton(),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _isProcessing
                ? const Center(child: CameraBusyBar())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bottom Left: Gallery Button
                        _galleryButton(),

                        // Center: Shutter Button
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            key: const Key('camera_shutter'),
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              child: Container(
                                height: 65,
                                width: 65,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: _backtohomepage,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/cancel.png',
                              height: 34,
                              width: 34,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
