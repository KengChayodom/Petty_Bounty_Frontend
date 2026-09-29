import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_glass.dart';
import '../../../core/ui/adaptive/breakpoints.dart';

/// Ink at half strength, as a literal so it can sit in const styles.
const Color _muted = Color(0x80120A04);

/// Success acknowledgement after a sighting report is sent to a pet's owner.
///
/// Takes plain pet fields (not a MatchModel) so both the discovery flow — which
/// has the full matched pet — and the targeted flow — which only knows the pet
/// it was reporting to — can reuse it. [bounty]/[petImageUrl] are optional; the
/// reward row and photo degrade gracefully when they aren't available.
class ReportSentScreen extends StatelessWidget {
  const ReportSentScreen({
    super.key,
    required this.petName,
    required this.sentAt,
    this.petImageUrl,
    this.bounty,
  });

  final String petName;
  final DateTime sentAt;
  final String? petImageUrl;
  final double? bounty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDaylight,
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8F0E3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 76,
                    color: Color(0xFF047857),
                  ),
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
                    color: kInk,
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
                    color: Color(0x99120A04),
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
                  color: Color(0x8C120A04),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kBrandDeep.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: kBrandDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'OWNER VERIFICATION',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: kBrandDeep,
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
                    backgroundColor: kBrandDeep,
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
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kInk.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: kInk.withValues(alpha: 0.07),
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
                  backgroundColor: kInk.withValues(alpha: 0.07),
                  backgroundImage:
                      (petImageUrl != null && petImageUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(petImageUrl!)
                      : null,
                  child: (petImageUrl == null || petImageUrl!.isEmpty)
                      ? Icon(Icons.pets, color: kInk.withValues(alpha: 0.35))
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  petName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: kInk,
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
                // Only shown when a bounty is known (discovery flow). The
                // targeted flow doesn't carry it, so the row is dropped.
                if (bounty != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EXPECTED REWARD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _muted,
                        ),
                      ),
                      Text(
                        '฿${NumberFormat('#,##0', 'en_US').format(bounty)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: kBrand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Text(
                      'SENT AT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _muted,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: _muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(sentAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kInk,
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
