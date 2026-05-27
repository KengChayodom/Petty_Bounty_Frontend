import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../domain/providers/nearby_pets_providers.dart';
import '../domain/entities/missing_pet_entity.dart';

Color _parseColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) return Colors.brown[300]!;

  String hex = hexColor;
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  try {
    return Color(int.parse(hex, radix: 16));
  } catch (e) {
    return Colors.brown[300]!;
  }
}

class PetDetailSheet extends ConsumerWidget {
  const PetDetailSheet({super.key});

  String _getSpeciesEmoji(String speciesName) {
    switch (speciesName.toLowerCase()) {
      case 'cat':
        return '🐱';
      case 'dog':
        return '🐶';
      case 'bird':
        return '🦜';
      default:
        return '🐾';
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return 'Unknown Date';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPetId = ref.watch(selectedPetIdProvider);
    final petsState = ref.watch(nearbyPetsProvider);

    if (selectedPetId == null) {
      return const SizedBox.shrink();
    }

    final pet = petsState.pets.firstWhere(
      (p) => p.id == selectedPetId,
      orElse: () => const MissingPetEntity(
        id: '',
        ownerId: '',
        petName: 'Unknown',
        species: 'Unknown',
        characteristics: {},
        bountyAmount: 0,
        latitude: 0.0,
        longitude: 0.0,
        lastSeenTime: '',
        imageUrl: '',
        status: 'Unknown',
        createdAt: '',
      ),
    );

    final String breed = pet.characteristics['breed'] ?? 'common';
    final String description = pet.characteristicsText.isNotEmpty
        ? pet.characteristicsText
        : "Looking for this sweet ${pet.species}.";

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          // 🚨 พระเอกจุดที่ 1: สั่งตัดขอบทุกอย่างที่ล้นออกไป ให้โค้งตาม BorderRadius ด้านบน
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // --- เนื้อหาหลัก ---
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. ส่วนรูปภาพและป้ายรางวัล
                    _buildHeaderImage(pet),

                    // 🚨 พระเอกจุดที่ 2: เว้นที่ว่างให้ป้าย Bounty ห้อยลงมาได้โดยไม่ทับข้อความ
                    const SizedBox(height: 40),

                    // 2. ข้อมูลย่อย
                    _buildSectionTitle('DETAILS'),
                    _buildDetailsRow(pet, breed),

                    // 3. รายละเอียด
                    _buildSectionTitle('DESCRIPTION'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '" $description "',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // 4. วันที่หาย
                    _buildSectionTitle('DATE LOST'),
                    _buildDateLostPill(_formatDateTime(pet.lastSeenTime)),

                    // 5. แผนที่
                    _buildSectionTitle('SIGHTING'),
                    _buildSightingMap(),

                    // 6. เจ้าของ
                    _buildSectionTitle('OWNER'),
                    _buildOwnerCard(),

                    const SizedBox(height: 30),

                    // 7. ปุ่ม Action
                    _buildActionButtons(context, pet),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // 🚨 พระเอกจุดที่ 3: จับ Handle bar มาลอยทับรูปภาพไปเลย จะได้ไม่เสียพื้นที่
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.7,
                      ), // สีขาวโปร่งแสงนิดๆ
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 🎨 ส่วนแยกย่อยของ UI (Widgets) ---

  Widget _buildHeaderImage(MissingPetEntity pet) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // รูปภาพ
        Stack(
          children: [
            CachedNetworkImage(
              imageUrl: pet.imageUrl,
              height: 320, // เพิ่มความสูงรูปนิดนึงให้สวยขึ้น
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 320,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 320,
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 48),
              ),
            ),
            // ไล่สีดำให้ตัวอักษรชื่อเด่นขึ้น
            Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        // ชื่อสัตว์
        Positioned(
          bottom: 45, // ขยับหนีป้าย Bounty นิดนึง
          left: 30,
          child: Text(
            pet.petName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // ป้ายตั้งค่าหัว (Bounty Badge)
        Positioned(
          bottom: -30, // ห้อยลงมาครึ่งนึงของกรอบรูป
          left: 40,
          right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Bounty',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '฿',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat('#,##0').format(pet.bountyAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // จุดแดง
        Positioned(
          bottom: -10,
          right: 35,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow(MissingPetEntity pet, String breed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDetailItem(
              'COLOR',
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _parseColor(pet.primaryColorHex),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            _buildDetailItem(
              'BREED',
              Text(
                breed,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDetailItem(
              'SPECIES',
              Text(
                _getSpeciesEmoji(pet.species),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, Widget content) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildDateLostPill(String formattedDate) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              formattedDate,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSightingMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Interactive Map Placeholder',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pet Owner',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'Tap to view profile',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MissingPetEntity pet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mission accepted: ${pet.petName}'),
                backgroundColor: Colors.green,
              ),
            );
          },
          backgroundColor: Colors.blue[600],
          elevation: 0,
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
        const SizedBox(width: 20),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 15,
      ), // ปรับช่องไฟให้สวยขึ้น
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
