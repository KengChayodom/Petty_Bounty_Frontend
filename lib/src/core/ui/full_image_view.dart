import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'skeleton/skeleton.dart';

/// Full-screen viewer for a photo: the image shown in full (pinch-to-zoom) on
/// a black backdrop, with a close (X) button.
///
/// In `core` rather than in a feature because more than one flow needs it —
/// the status tracker's sighting photos, and the sightings flow's own
/// comparison shots, which are local files rather than URLs.
class FullImageView extends StatelessWidget {
  /// A photo that lives on the network, disk-cached by [CachedNetworkImage].
  const FullImageView({super.key, required String imageUrl})
    : _url = imageUrl,
      _path = null;

  /// A photo the user just took, still only on this device.
  const FullImageView.file({super.key, required String path})
    : _path = path,
      _url = null;

  final String? _url;
  final String? _path;

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
              child: Center(child: _image()),
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

  Widget _image() {
    final path = _path;
    if (path != null) {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _Broken(),
      );
    }
    return CachedNetworkImage(
      imageUrl: _url!,
      fit: BoxFit.contain,
      // Deliberately NO memCacheWidth here, unlike the header and the timeline
      // card: this view zooms to 4x, so it is the one place that genuinely
      // needs every pixel. The bytes come off the same disk-cached file those
      // two already downloaded. No progress bar even though bytes are known —
      // a shimmering frame on the black backdrop, per the app's no-spinner rule.
      placeholder: (_, _) => const Skeletonizer.zone(
        effect: AppSkeletons.onDark,
        child: Bone(width: 240, height: 320, uniRadius: 12),
      ),
      errorWidget: (_, _, _) => const _Broken(),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
  );
}
