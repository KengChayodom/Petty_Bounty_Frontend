import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';

/// Primary color swatches + custom color picker + distinguishing traits (description).
class CollarMarkerWidget extends ConsumerWidget {
  const CollarMarkerWidget({super.key, required this.traitsController});

  final TextEditingController traitsController;

  static const List<Map<String, String>> _presetColors = [
    {"name": "Golden", "hex": "#D4AF37"},
    {"name": "Black", "hex": "#000000"},
    {"name": "White", "hex": "#FFFFFF"},
    {"name": "Brown", "hex": "#8B4513"},
    {"name": "Cream", "hex": "#F5F5DC"},
    {"name": "Orange", "hex": "#FF9800"},
    {"name": "Gray", "hex": "#808080"},
  ];

  static const List<String> _extendedSwatches = [
    "#FF1744", "#F50057", "#D500F9", "#651FFF",
    "#3D5AFE", "#2979FF", "#00E5FF", "#1DE9B6",
    "#00E676", "#76FF03", "#FFEA00", "#FF9100",
  ];

  void _showCustomColorDialog(
      BuildContext context, WidgetRef ref, String currentHex) {
    final textController = TextEditingController(text: currentHex);
    String selectedHex = currentHex;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Color parsedColor;
            try {
              final clean = selectedHex.replaceAll('#', '');
              parsedColor = Color(int.parse('0xFF$clean'));
            } catch (_) {
              parsedColor = Colors.blue;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.palette_outlined, color: Color(0xFF0022FF)),
                  SizedBox(width: 8),
                  Text(
                    'CUSTOM PET COLOR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color preview box
                    Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: parsedColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        selectedHex.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: parsedColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Extended Color Palette:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _extendedSwatches.map((hex) {
                        final isSel = selectedHex.toUpperCase() ==
                            hex.toUpperCase();
                        final c = Color(
                            int.parse('0xFF${hex.replaceAll('#', '')}'));
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedHex = hex;
                              textController.text = hex;
                              errorText = null;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF0022FF)
                                    : Colors.grey.shade300,
                                width: isSel ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Custom Hex Code (#RRGGBB):',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: '#FF9900',
                        errorText: errorText,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedHex = val.trim();
                          if (!selectedHex.startsWith('#')) {
                            selectedHex = '#$selectedHex';
                          }
                          if (!RegExp(r'^#[0-9A-Fa-f]{6}$')
                              .hasMatch(selectedHex)) {
                            errorText = 'Invalid hex. Use #RRGGBB format';
                          } else {
                            errorText = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: errorText != null
                      ? null
                      : () {
                          var finalHex = selectedHex.trim();
                          if (!finalHex.startsWith('#')) {
                            finalHex = '#$finalHex';
                          }
                          if (RegExp(r'^#[0-9A-Fa-f]{6}$')
                              .hasMatch(finalHex)) {
                            ref
                                .read(lostPetPostFormProvider.notifier)
                                .updateColor(finalHex.toUpperCase());
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0022FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Color'),
                ),
              ],
            );
          },
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
    final currentHex = primaryColorHex ?? '#D4AF37';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PRIMARY COLOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentHex.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._presetColors.map((c) {
                final isSelected =
                    currentHex.toUpperCase() == c["hex"]!.toUpperCase();
                final colorVal =
                    Color(int.parse(c["hex"]!.replaceAll('#', '0xFF')));
                return GestureDetector(
                  onTap: () => notifier.updateColor(c["hex"]!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorVal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0022FF)
                            : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        if (colorVal == Colors.white)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              // Custom Color Picker Button
              GestureDetector(
                onTap: () =>
                    _showCustomColorDialog(context, ref, currentHex),
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0022FF),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.color_lens_outlined,
                    size: 18,
                    color: Color(0xFF0022FF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CHARACTERISTICS / TRAITS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.0,
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
            fillColor: Colors.grey[100],
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

