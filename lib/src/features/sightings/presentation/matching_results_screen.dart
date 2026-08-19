import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petty_bounty/src/core/ui/snackbar_helpers.dart';
import '../data/models/match_model.dart';
import '../domain/sighting_providers.dart';
import 'final_review_screen.dart';

class MatchingResultsScreen extends ConsumerStatefulWidget {
  final String? imagePath; // รับ path รูปภาพที่เราถ่ายมาจากหน้า Verification
  final double? latitude; // พิกัดที่ถ่าย sighting (สำหรับหน้า Final Review)
  final double? longitude;
  const MatchingResultsScreen({
    super.key,
    this.imagePath,
    this.latitude,
    this.longitude,
  });

  @override
  ConsumerState<MatchingResultsScreen> createState() =>
      _MatchingResultsScreenState();
}

class _MatchingResultsScreenState extends ConsumerState<MatchingResultsScreen> {
  dynamic _selectedMatch;

  void _confirmMatch(dynamic match) {
    // The sighting AND its AI matches are already persisted by POST /sightings/;
    // confirming a match routes the hunter to Final Review before the sent
    // acknowledgement. If we somehow have no coords, fall back to the old
    // acknowledge-and-return behaviour rather than opening a broken map.
    if (match == null || widget.latitude == null || widget.longitude == null) {
      context.showSuccessSnackBar(
        'Sighting submitted. The owner will be notified if it matches.',
      );
      context.go('/');
      return;
    }
    // Id of the sighting created upstream (POST /sightings/), so Final Review
    // can PATCH its action_type (Spotted/Rescue).
    final sightingId = ref.read(sightingNotifierProvider).sighting?.id;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinalReviewScreen(
          match: match as MatchModel,
          imagePath: widget.imagePath,
          latitude: widget.latitude!,
          longitude: widget.longitude!,
          sightingId: sightingId,
        ),
      ),
    );
  }

  Widget _buildStars(double similarity) {
    int starCount = 1;
    if (similarity >= 0.9) {
      starCount = 3;
    } else if (similarity >= 0.7) {
      starCount = 2;
    }

    return Row(
      children: List.generate(3, (index) {
        return Icon(
          Icons.star,
          color: index < starCount ? Colors.amber : Colors.transparent,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The sighting is already saved by the time this screen shows. Every back
    // action — the on-screen buttons AND the Android system back / swipe — must
    // return to the map, never to the verification/re-analyze screen (which
    // would let the user re-submit and create a duplicate sighting).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/');
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final sightingState = ref.watch(sightingNotifierProvider);
    final matches = sightingState.matches;

    // ถ้าไม่มีข้อมูลแมตช์ โชว์หน้าจอแจ้งเตือน
    if (matches.isEmpty && !sightingState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Matching Results'),
          backgroundColor: const Color(0xFFED7645),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No matching pets found nearby',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your sighting has been recorded. If a matching pet is reported later, you will be notified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7645),
                  ),
                  child: const Text(
                    'Go Home',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayMatch =
        _selectedMatch ?? (matches.isNotEmpty ? matches.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      body: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 28,
                        color: Colors.black87,
                      ),
                      onPressed: () => context.go('/'),
                    ),
                    const Text(
                      'MATCHING',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Sighting vs Matching
                if (displayMatch != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // รูปภาพ SIGHTING (จากรูปที่ถ่าย)
                      Column(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                              image: widget.imagePath != null
                                  ? DecorationImage(
                                      image: FileImage(File(widget.imagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null, // กันเหนียวเผื่อ path หาย
                            ),
                            child: widget.imagePath == null
                                ? const Icon(Icons.photo)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'SIGHTING',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),

                      // ไอคอนเปรียบเทียบ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.compare_arrows,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                            const SizedBox(height: 10),
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.amber[600],
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      // รูปภาพ MATCHING
                      Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.blueAccent,
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: displayMatch.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: -5,
                                right: -5,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MATCHING',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                // 3. OTHER CANDIDATES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OTHER CANDIDATES',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            'MATCH SCORE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // 4. ลิสต์ตัวเลือก
                Expanded(
                  child: ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final isSelected = displayMatch?.id == match.id;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedMatch = match),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(15),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 2)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundImage: CachedNetworkImageProvider(
                                      match.imageUrl,
                                    ),
                                  ),
                                  const Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 6,
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.petName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text(
                                          '฿',
                                          style: TextStyle(
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          match.bountyAmount.toStringAsFixed(0),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(match.distanceMeters / 1000).toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStars(match.similarity),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 5. ปุ่ม Actions
                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 15),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: InkWell(
                          onTap: displayMatch == null
                              ? null
                              : () => _confirmMatch(displayMatch),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF48B884),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: Text(
                                'CONFIRM MATCH',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
