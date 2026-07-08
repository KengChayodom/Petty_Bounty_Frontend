import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

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

class CameraScreen extends StatefulWidget {
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
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
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
        ResolutionPreset.high,
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
  Map<String, dynamic> _verificationArgs(String imagePath) => {
    'imagePath': imagePath,
    'targetPetId': widget.targetPetId,
    'targetSpecies': widget.targetSpecies,
    'targetPetName': widget.targetPetName,
  };

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
        context.pushNamed('verification', extra: _verificationArgs(photo.path));
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
      );

      if (photo != null && mounted) {
        context.pushNamed('verification', extra: _verificationArgs(photo.path));
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
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
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
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
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
