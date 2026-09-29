import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petty_bounty/src/core/ui/snackbar_helpers.dart';
import '../../../core/theme/app_glass.dart';
import '../../../core/ui/full_image_view.dart';
import '../data/models/match_model.dart';
import '../domain/sighting_providers.dart';
import 'final_review_screen.dart';

/// The similarity rating's own colour. Amber reads as a rating rather than
/// as brand orange, which on this screen would mean bounty.
const Color _star = Color(0xFFE8A302);

/// Ink at half strength, as a literal so it can sit in const styles.
const Color _muted = Color(0x80120A04);

/// The comparison pair, deliberately unequal. The sighting is the reference
/// the hunter already knows; the matched pet is the unknown being judged, and
/// it is the one that changes as candidates are tapped, so it gets the room.
/// Together with the glyphs between them these fill the content width.
const double _sightingSize = 122;
const double _matchSize = 162;

/// The candidate thumbnail, and with it the card's height. The card is sized
/// by the photo rather than the other way round: on this screen the photo is
/// the thing being judged and the text beside it is the caption.
const double _thumbSize = 104;

/// The candidate card at rest, and the same card carrying [kBrand] at 18%.
/// Pre-blended as a literal so the two can be cross-faded by AnimatedContainer.
const Color _card = Color(0xFF241A12);
const Color _cardSelected = Color(0xFF4A2B14);

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
  MatchModel? _selectedMatch;

  void _confirmMatch(MatchModel? match) {
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
          match: match,
          imagePath: widget.imagePath,
          latitude: widget.latitude!,
          longitude: widget.longitude!,
          sightingId: sightingId,
        ),
      ),
    );
  }

  /// How long a state change takes, or nothing at all when the platform asks
  /// for reduced motion — the same contract every other animation in the app
  /// honours.
  Duration _motion([int ms = 180]) => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: ms);

  /// Opens a photo full screen, where it can actually be inspected.
  ///
  /// This screen's whole job is "is this the same animal?", and 110 px of
  /// thumbnail is not enough to answer it. The viewer already existed for the
  /// status tracker; it just was not reachable from here.
  void _openPhoto({String? url, String? path}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => path != null
            ? FullImageView.file(path: path)
            : FullImageView(imageUrl: url!),
      ),
    );
  }

  Widget _buildStars(MatchModel match) {
    // The backend rates each card from the score that ordered the list, so the
    // stars cannot contradict the order. See MatchStars in match_model.dart.
    final starCount = match.stars;

    // An unfilled star is outlined, not transparent. Drawn transparent, a weak
    // match rendered as one lone star beside two gaps, and nothing on screen
    // said the scale was out of three.
    return Row(
      children: List.generate(3, (index) {
        final filled = index < starCount;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? _star : _star.withValues(alpha: 0.35),
          size: 21,
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
        backgroundColor: kDaylight,
        appBar: AppBar(
          title: const Text('Matching Results'),
          // Not white-on-brand: kBrand against white measures about 2.7:1,
          // under AA for text. Ink on the page colour is what the rest of the
          // app uses for a bar like this.
          backgroundColor: kDaylight,
          foregroundColor: kInk,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: kInk.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No matching pets found nearby',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your sighting has been recorded. If a matching pet is reported later, you will be notified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _muted),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(backgroundColor: kBrand),
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

    final MatchModel? displayMatch =
        _selectedMatch ?? (matches.isNotEmpty ? matches.first : null);

    return Scaffold(
      backgroundColor: kInk,
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
                      icon: const Icon(Icons.arrow_back, size: 28, color: kInk),
                      onPressed: () => context.go('/'),
                    ),
                    const Text(
                      'MATCHING',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: kInk,
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
                          GestureDetector(
                            onTap: widget.imagePath == null
                                ? null
                                : () => _openPhoto(path: widget.imagePath),
                            child: Container(
                              width: _sightingSize,
                              height: _sightingSize,
                              decoration: BoxDecoration(
                                color: kInk.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                                image: widget.imagePath != null
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(widget.imagePath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null, // กันเหนียวเผื่อ path หาย
                              ),
                              child: widget.imagePath == null
                                  ? const Icon(Icons.photo)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'SIGHTING',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),

                      // ไอคอนเปรียบเทียบ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.compare_arrows,
                              color: kBrandLight,
                              size: 28,
                            ),
                            const SizedBox(height: 10),
                            Icon(Icons.auto_awesome, color: _star, size: 20),
                          ],
                        ),
                      ),

                      // รูปภาพ MATCHING
                      Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _openPhoto(url: displayMatch.imageUrl),
                                child: Container(
                                  width: _matchSize,
                                  height: _matchSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: kBrandLight,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    // Cross-faded, because this photo is what
                                    // changes when a candidate is tapped and a
                                    // hard swap goes unnoticed by a user whose
                                    // eyes are still on the list below.
                                    child: AnimatedSwitcher(
                                      duration: _motion(240),
                                      child: CachedNetworkImage(
                                        key: ValueKey(displayMatch.imageUrl),
                                        imageUrl: displayMatch.imageUrl,
                                        width: _matchSize,
                                        height: _matchSize,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: -6,
                                right: -6,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: kBrandErrorDeep,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Not 'MATCHING' — that is the page's own title,
                          // two hundred pixels above. This caption names the
                          // pet being compared, whichever candidate is picked.
                          const Text(
                            'MATCHED PET',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
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
                        color: _muted,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kInk.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: _star, size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            'MATCH SCORE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0x99120A04),
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
                        child: AnimatedScale(
                          scale: isSelected ? 1.02 : 1,
                          duration: _motion(),
                          curve: Curves.easeOut,
                          child: AnimatedContainer(
                            duration: _motion(),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? _cardSelected : _card,
                              borderRadius: BorderRadius.circular(15),
                              // Always present, transparent when unselected: a
                              // border that appears from nothing would shift the
                              // card's contents by 4 px on every tap.
                              border: Border.all(
                                color: isSelected
                                    ? kBrandLight
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: kBrand.withValues(alpha: 0.35),
                                        blurRadius: 24,
                                        spreadRadius: -6,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // A rounded square, not a circle. A circle crops
                                // the animal to a disc and throws away the body
                                // and the markings, which are exactly what tells
                                // one tabby from another.
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          _openPhoto(url: match.imageUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: CachedNetworkImage(
                                          imageUrl: match.imageUrl,
                                          width: _thumbSize,
                                          height: _thumbSize,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => Container(
                                            width: _thumbSize,
                                            height: _thumbSize,
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                          errorWidget: (_, _, _) => Container(
                                            width: _thumbSize,
                                            height: _thumbSize,
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                            child: const Icon(
                                              Icons.pets,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundColor: kBrandErrorDeep,
                                      ),
                                    ),
                                    // Top-left, because the corner opposite is
                                    // already taken by the red dot this screen
                                    // has always drawn.
                                    Positioned(
                                      top: -6,
                                      left: -6,
                                      child: AnimatedScale(
                                        scale: isSelected ? 1 : 0,
                                        duration: _motion(),
                                        curve: Curves.easeOutBack,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: kBrand,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _cardSelected,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        match.petName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Text(
                                            '฿',
                                            style: TextStyle(
                                              color: kBrandLight,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            match.bountyAmount.toStringAsFixed(
                                              0,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(match.distanceMeters / 1000).toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStars(match),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 5. ปุ่ม Actions
                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 15),
                  // Both buttons to the taller one's height. Their labels are
                  // different sizes, so padding alone left them mismatched.
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Not destructive, and it must not look it: the
                        // sighting was persisted by POST /sightings/ before this
                        // screen opened, so leaving here discards nothing. A red
                        // unlabelled cross said the opposite.
                        InkWell(
                          onTap: () => context.go('/'),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: kInk.withValues(alpha: 0.06),
                              border: Border.all(
                                color: kInk.withValues(alpha: 0.12),
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'NONE MATCH',
                              style: TextStyle(
                                color: Color(0xB3120A04),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
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
                                color: Color(0xFF047857),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
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
                      ],
                    ),
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
