import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
       
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false, 
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    // Always dispose the controller to free up resources
    _cameraController?.dispose();
    super.dispose();
  }

  // Action 1: Take photo from live camera
  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() { _isProcessing = true; });

    try {
      final XFile photo = await _cameraController!.takePicture();
      if (mounted) {
        context.pushNamed('verification', extra: photo.path);
      }
    } catch (e) {
      print('Error taking picture: $e');
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  // Action 2: Pick from Gallery (Bottom Left Button)
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    
    setState(() { _isProcessing = true; });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (photo != null && mounted) {
        context.pushNamed('verification', extra: photo.path);
      }
    } catch (e) {
      print('Error picking from gallery: $e');
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while camera is starting
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The Live Camera Feed
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // Top Action Bar (Close button)
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),

          // 2. The Bottom Control Bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _isProcessing 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bottom Left: Gallery Button
                      GestureDetector(
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
                      ),

                      // Center: Shutter Button
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
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

                      // Bottom Right: Empty space to balance the row layout
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}