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

      final String uploadedUrl = await repository.uploadImage(widget.imagePath);
      final analysisResult = await repository.analyzeImage(uploadedUrl);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _detectedSpecies = analysisResult['data']['species'];
        });

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
    String? selectedSpecies = _detectedSpecies;
    final List<String> speciesList = ['Cat', 'Dog', 'Bird'];
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
                    // --- ส่วน UI แรก: แบบในรูป (ยังไม่กด Reject) ---
                    if (!showDropdown) ...[
                      // รูปวงกลม + ไอคอนคำถาม
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
                              backgroundColor: Color(0xFFED7645), // สีส้มแบบในรูป
                              child: Icon(Icons.question_mark,
                                  color: Colors.white, size: 20),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                            onTap: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Confirmed: $_detectedSpecies. Proceeding..."),
                                ),
                              );
                            },
                            child: const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white, size: 40),
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
                              child: Icon(Icons.close, color: Colors.white, size: 40),
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
                        value: selectedSpecies != _detectedSpecies ? selectedSpecies : null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.pop(); // กลับไปหน้ากล้อง
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedSpecies == null
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Confirmed manually: $selectedSpecies. Proceeding..."),
                                      ),
                                    );
                                  },
                            child: const Text("Confirm"),
                          ),
                        ],
                      )
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
                  Text("AI is analyzing...", style: TextStyle(color: Colors.white, fontSize: 16)),
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
          )
        ],
      ),
    );
  }
}