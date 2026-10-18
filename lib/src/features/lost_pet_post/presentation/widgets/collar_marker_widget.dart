import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';

/// Tap-to-pick coat colors from photo widget (Primary & Secondary tiles).
class CollarMarkerWidget extends ConsumerWidget {
  const CollarMarkerWidget({super.key, required this.traitsController});

  final TextEditingController traitsController;

  void _openColorPicker({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final state = ref.read(lostPetPostFormProvider);
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    if (state.imagePath == null && state.imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pet photo in Step 1 first!'),
          backgroundColor: kBrandDeep,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PetImageEyedropperDialog(
          imagePath: state.imagePath,
          imageUrl: state.imageUrl,
          initialHex: state.primaryColorHex ?? '#D0D0D0',
          onColorConfirmed: notifier.updateColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColorHex = ref.watch(
      lostPetPostFormProvider.select((state) => state.primaryColorHex),
    );
    final notifier = ref.read(lostPetPostFormProvider.notifier);

    final currentPrimaryHex = (primaryColorHex ?? '#D0D0D0').toUpperCase();

    Color parseColor(String hex) {
      try {
        final clean = hex.replaceAll('#', '');
        return Color(int.parse('0xFF$clean'));
      } catch (_) {
        return kBrandDeep;
      }
    }

    final primaryColor = parseColor(currentPrimaryHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coat colour',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: kInkMuted,
          ),
        ),
        const SizedBox(height: 10),

        // SINGLE COAT COLOR TILE (NO HEX CODE SHOWN)
        GestureDetector(
          onTap: () => _openColorPicker(context: context, ref: ref),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: kBrandDeep,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: kInk.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: kInkMuted.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Coat colour',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.colorize,
                  size: 18,
                  color: kBrandDeep,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),
        const Text(
          'Marks and traits',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: kInkMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: traitsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                "e.g., White patch on chest, friendly, responds to Luna",
            filled: true,
            fillColor: kFieldFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => notifier.updateTraits(value),
        ),
      ],
    );
  }
}

/// Modal Eyedropper dialog for picking a single color directly from the pet photo.
class PetImageEyedropperDialog extends StatefulWidget {
  const PetImageEyedropperDialog({
    super.key,
    this.imagePath,
    this.imageUrl,
    required this.initialHex,
    required this.onColorConfirmed,
  });

  final String? imagePath;
  final String? imageUrl;
  final String initialHex;
  final ValueChanged<String> onColorConfirmed;

  @override
  State<PetImageEyedropperDialog> createState() =>
      _PetImageEyedropperDialogState();
}

class _PetImageEyedropperDialogState extends State<PetImageEyedropperDialog> {
  final GlobalKey _imageKey = GlobalKey();

  late Color _sampledColor;
  late String _sampledHex;
  Offset? _touchOffset;

  @override
  void initState() {
    super.initState();
    _sampledHex = widget.initialHex.toUpperCase();
    try {
      final clean = _sampledHex.replaceAll('#', '');
      _sampledColor = Color(int.parse('0xFF$clean'));
    } catch (_) {
      _sampledColor = kBrandDeep;
    }
  }

  Future<void> _sampleColorAt(Offset localOffset) async {
    try {
      final boundary =
          _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage();
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final Size renderSize = boundary.size;
      final double scaleX = image.width / renderSize.width;
      final double scaleY = image.height / renderSize.height;

      final int x = (localOffset.dx * scaleX).clamp(0, image.width - 1).toInt();
      final int y = (localOffset.dy * scaleY).clamp(0, image.height - 1).toInt();

      final int pixelOffset = (y * image.width + x) * 4;

      final int r = byteData.getUint8(pixelOffset);
      final int g = byteData.getUint8(pixelOffset + 1);
      final int b = byteData.getUint8(pixelOffset + 2);

      final String hex =
          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
              .toUpperCase();

      if (mounted) {
        setState(() {
          _sampledColor = Color.fromARGB(255, r, g, b);
          _sampledHex = hex;
          _touchOffset = localOffset;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const titleText = 'Pick the main colour';
    const themeColor = kBrandDeep;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.colorize, color: themeColor, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      titleText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Touch on your pet photo to select exact coat color',
              style: TextStyle(fontSize: 12, color: kInkMuted),
            ),
            const SizedBox(height: 14),

            // PET PHOTO DISPLAY WITH COLOR SAMPLING
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onPanDown: (details) => _sampleColorAt(details.localPosition),
                onPanUpdate: (details) => _sampleColorAt(details.localPosition),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      key: _imageKey,
                      child: widget.imagePath != null
                          ? Image.file(
                              File(widget.imagePath!),
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                    ),
                    if (_touchOffset != null)
                      Positioned(
                        left: _touchOffset!.dx - 24,
                        top: _touchOffset!.dy - 24,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _sampledColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: kInk.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // SELECTED COLOR PREVIEW BAR (NO HEX DISPLAYED)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kFieldFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _sampledColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kInkMuted.withValues(alpha: 0.3)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Main colour',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: kInkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CONFIRM BUTTON
            ElevatedButton(
              onPressed: () {
                widget.onColorConfirmed(_sampledHex);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
