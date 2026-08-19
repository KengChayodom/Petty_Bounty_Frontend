import 'package:flutter/material.dart';

import '../../../../core/ui/skeleton/skeleton.dart';

/// Full-screen viewer for a sighting photo: the image shown in full
/// (pinch-to-zoom) on a black backdrop, with a close (X) button.
class FullImageView extends StatelessWidget {
  const FullImageView({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      // No progress bar even though `progress` carries byte
                      // counts — a shimmering frame on the black backdrop.
                      : const Skeletonizer.zone(
                          effect: AppSkeletons.onDark,
                          child: Bone(
                            width: 240,
                            height: 320,
                            uniRadius: 12,
                          ),
                        ),
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
          ),
          // Close (X) button.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
