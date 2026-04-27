import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../data/sighting_repository.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const VerificationScreen({super.key, required this.imagePath});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _isLoading = true;
  String? _detectedSpecies;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processAIAnalysis();
  }

  Future<void> _processAIAnalysis() async {
    try {
      final repository = ref.read(sightingRepositoryProvider);

      // 1. Upload to Supabase via FastAPI
      final String uploadedUrl = await repository.uploadImage(widget.imagePath);

      // 2. Analyze via YOLO
      final analysisResult = await repository.analyzeImage(uploadedUrl);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _detectedSpecies = analysisResult['data']['species'];
        });

        // 3. Prompt user confirmation
        if (_detectedSpecies != 'Unknown') {
          _showConfirmationDialog();
        } else {
          _errorMessage = "No target animal detected.";
        }
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

  void _showConfirmationDialog() {
  String? _selectedSpecies = _detectedSpecies;
  final List<String> _speciesList = ['Cat', 'Dog', 'Bird'];
  bool _showDropdown = false; 

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("AI Verification"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
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

                // Dropdown — โชว์หลังกด Reject
                if (_showDropdown) ...[
                  const SizedBox(height: 16),
                  const Text("Select the correct species:"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecies != _detectedSpecies ? _selectedSpecies : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text("Select species"),
                    items: _speciesList.map((species) {
                      return DropdownMenuItem(
                        value: species,
                        child: Text(species),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedSpecies = value;
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
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 18),
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
                ],
              ],
            ),
            actions: [
              // Reject → เปิด dropdown
              if (!_showDropdown)
                TextButton(
                  child: const Text("Reject"),
                  onPressed: () {
                    setDialogState(() {
                      _showDropdown = true;
                      _selectedSpecies = null; // reset
                    });
                  },
                ),

              // Cancel — โชว์หลัง reject
              if (_showDropdown)
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                ),

              ElevatedButton(
                onPressed: (_showDropdown && _selectedSpecies == null)
                    ? null // disabled ถ้า dropdown เปิดแต่ยังไม่เลือก
                    : () {
                        Navigator.of(context).pop();
                        // TODO: Call /sightings with _selectedSpecies
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Confirmed: $_selectedSpecies. Proceeding to matching..."),
                          ),
                        );
                      },
                child: const Text("Confirm"),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing Sighting')),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("AI is analyzing the image..."),
                ],
              )
            : _errorMessage != null
                ? Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  )
                : Image.file(File(widget.imagePath)), // Show the photo taken
      ),
    );
  }
}