import 'package:flutter/material.dart';

import '../../../core/ui/skeleton/skeleton.dart';

/// Skeleton for `PetDetailView`, shown by both of its entry points while the
/// pet is fetched by id (the push deep-link case, or a pet outside the loaded
/// map radius — see `PetDetailResolver`).
///
/// Unlike the profile/timeline skeletons this one is drawn from explicit
/// [Bone]s inside a [Skeletonizer.zone] rather than by skeletonizing the real
/// widget: `PetDetailView`'s header is a `CachedNetworkImage`, and feeding it a
/// mock URL would fire a network fetch just to render a placeholder.
///
/// The section order and the fixed heights below mirror `PetDetailView`
/// (320px header, 150px map slot, 20px side padding), so the real content
/// lands where the skeleton stood.
class PetDetailSkeleton extends StatelessWidget {
  const PetDetailSkeleton({super.key, this.scrollController});

  /// Passed through from the draggable sheet so the placeholder scrolls with
  /// the same gesture as the loaded content.
  final ScrollController? scrollController;

  static const _sidePadding = EdgeInsets.symmetric(horizontal: 20);

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 40),
            _sectionTitle(width: 74),
            _detailsRow(),
            _sectionTitle(width: 116),
            const Padding(
              padding: _sidePadding,
              child: Bone.multiText(lines: 2, textAlign: TextAlign.center),
            ),
            _sectionTitle(width: 96),
            const Center(
              child: Bone(width: 210, height: 44, uniRadius: 20),
            ),
            _sectionTitle(width: 92),
            const Padding(
              padding: _sidePadding,
              child: Bone(height: 150, uniRadius: 20),
            ),
            _sectionTitle(width: 66),
            _ownerCard(),
            const SizedBox(height: 30),
            _actionButtons(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// The 320px hero image, the pet name over it, and the bounty pill that
  /// overhangs its bottom edge by 30px.
  Widget _header() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Bone(height: 320),
        const Positioned(
          bottom: 45,
          left: 30,
          child: Bone(width: 190, height: 40, uniRadius: 8),
        ),
        const Positioned(
          bottom: -30,
          left: 40,
          right: 40,
          child: Bone(height: 78, uniRadius: 30),
        ),
      ],
    );
  }

  /// Matches `_buildSectionTitle`: centered, 25px above / 15px below.
  Widget _sectionTitle({required double width}) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 15),
      child: Center(child: Bone(width: width, height: 14, uniRadius: 7)),
    );
  }

  /// The white COLOR / BREED / SPECIES card.
  Widget _detailsRow() {
    return Padding(
      padding: _sidePadding,
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DetailItemSkeleton(child: Bone.circle(size: 24)),
            _DetailItemSkeleton(child: Bone(width: 56, height: 16, uniRadius: 8)),
            _DetailItemSkeleton(child: Bone.square(size: 24, uniRadius: 6)),
          ],
        ),
      ),
    );
  }

  Widget _ownerCard() {
    return Padding(
      padding: _sidePadding,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          children: [
            Bone.circle(size: 50),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(width: 100, height: 16, uniRadius: 8),
                SizedBox(height: 6),
                Bone(width: 130, height: 12, uniRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Bone.circle(size: 56),
        SizedBox(width: 20),
        Bone.square(size: 48, uniRadius: 15),
      ],
    );
  }
}

/// One COLOR / BREED / SPECIES column: a label bone above the value bone.
class _DetailItemSkeleton extends StatelessWidget {
  const _DetailItemSkeleton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Bone(width: 54, height: 12, uniRadius: 6),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
