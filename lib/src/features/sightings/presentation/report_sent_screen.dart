import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models/match_model.dart';

/// Success acknowledgement after a sighting report is sent to a pet's owner.
class ReportSentScreen extends StatelessWidget {
  const ReportSentScreen({
    super.key,
    required this.match,
    required this.sentAt,
  });

  final MatchModel match;
  final DateTime sentAt;

  static const _orange = Color(0xFFEE6D33);
  static const _blue = Color(0xFF3B5BFE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Color(0xFFCDEEDA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 76, color: Color(0xFF2E7D5B)),
              ),
            ),
            const SizedBox(height: 28),
            const Center(
              child: Text(
                'REPORT SENT !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Your information has been sent to the owner,\nplease wait for confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _summaryCard(),
            const SizedBox(height: 24),
            const Text(
              'NEXT STEPS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _blue.withValues(alpha: 0.12),
                  child: const Icon(Icons.verified_user_outlined,
                      color: _blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'OWNER VERIFICATION',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: _blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.home_rounded, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: match.imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(match.imageUrl)
                      : null,
                  child: match.imageUrl.isEmpty
                      ? const Icon(Icons.pets, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  match.petName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXPECTED REWARD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '฿${NumberFormat('#,##0', 'en_US').format(match.bountyAmount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'SENT AT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(sentAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
