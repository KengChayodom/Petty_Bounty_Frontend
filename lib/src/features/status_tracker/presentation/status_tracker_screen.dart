import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/skeleton/skeleton.dart';
import '../data/models/sighting_activity.dart';
import '../data/status_tracker_repository.dart';
import '../domain/providers/status_tracker_providers.dart';
import 'widgets/activity_card.dart';
import 'widgets/activity_timeline_skeleton.dart';
import 'widgets/full_image_view.dart';
import 'widgets/sighting_map_view.dart';
import 'widgets/status_stepper.dart';

/// Owner-facing "Status Tracker" screen: the search progress of a single lost
/// pet report — a 4-stage stepper plus the reverse-chronological sighting
/// timeline. Reached from the Profile → Owner tab by tapping a report card.
class StatusTrackerScreen extends ConsumerStatefulWidget {
  const StatusTrackerScreen({
    super.key,
    required this.petId,
    required this.petName,
    this.petImageUrl,
    this.isResolved = false,
  });

  final String petId;
  final String petName;
  final String? petImageUrl;

  /// Whether the report was already resolved before opening this screen (drawn
  /// from the caller's own status). Seeds the stepper straight to RESCUE.
  final bool isResolved;

  @override
  ConsumerState<StatusTrackerScreen> createState() =>
      _StatusTrackerScreenState();
}

class _StatusTrackerScreenState extends ConsumerState<StatusTrackerScreen> {
  bool _isConfirming = false;
  // Flips to true once the owner ends the search from this screen, so the
  // stepper jumps to RESCUE and the confirm button disappears without needing
  // a full re-fetch round-trip.
  bool _locallyResolved = false;

  // The card a decision is currently in flight for, so only that card's
  // buttons go busy rather than every card at once.
  String? _decidingId;

  /// Whether the report is resolved. `_locallyResolved` (this session's own
  /// end-search tap) always wins; otherwise the authoritative fetched status
  /// decides, falling back to the seed passed in only while it's still loading.
  bool _isResolved(String? realStatus) {
    if (_locallyResolved) return true;
    if (realStatus == null) return widget.isResolved;
    return realStatus.toLowerCase() == 'found';
  }

  /// Stepper stage:
  ///   RESCUE  — the search has been ended (owner confirmed / backend "Found").
  ///   SPOTTED — at least one sighting has been reported against the pet.
  ///   PENDING — the post is live but no sighting has come in yet (waiting).
  ///   LOST    — the base step; always lit beneath whichever is current, so it
  ///             is never returned as the "current" stage (a post always
  ///             exists once this screen is open).
  ///
  /// `realStatus` is null only while the backend fetch is in flight; the seed
  /// passed in covers that window so the stepper doesn't flash.
  TrackerStage _deriveStage(String? realStatus, List<SightingActivity> items) {
    if (_locallyResolved) return TrackerStage.rescue;
    if (realStatus != null) {
      if (realStatus.toLowerCase() == 'found') return TrackerStage.rescue;
    } else if (widget.isResolved) {
      return TrackerStage.rescue;
    }

    // Any reported sighting means the pet has been spotted; none yet → waiting.
    if (items.isNotEmpty || realStatus?.toLowerCase() == 'spotted') {
      return TrackerStage.spotted;
    }
    return TrackerStage.pending;
  }

  /// The one card the owner may act on: the OLDEST still-undecided card.
  ///
  /// The list arrives newest-first, so that is the last Pending entry in it.
  /// The rule is enforced by the backend (409) — this only keeps the screen
  /// from offering a button that would be refused. Its purpose is that nobody
  /// who helped is skipped over on the way to closing the case: scoring counts
  /// confirmed cards only, so a card left Pending earns its hunter nothing.
  SightingActivity? _nextCard(List<SightingActivity> items) {
    for (final item in items.reversed) {
      if (!item.isDecided) return item;
    }
    return null;
  }

  Future<void> _decide(SightingActivity item, String decision) async {
    // Confirming a catch is the irreversible one: it ends the search and moves
    // every point the case will ever pay. Merely confirming a sighting is not,
    // so it goes through without a prompt.
    if (item.isCaught && decision == 'Confirmed') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm rescue?'),
          content: const Text(
            'This confirms your pet is home. The search ends and reward points '
            'are shared out to everyone whose sighting you confirmed. '
            'You can\'t undo this.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF7D),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _decidingId = item.id);
    try {
      final result = await ref
          .read(statusTrackerRepositoryProvider)
          .decideSighting(widget.petId, item.id, decision);
      if (!mounted) return;

      final closed = result['search_closed'] == true;
      final awards = (result['awards'] as List<dynamic>? ?? const []).length;
      setState(() {
        _decidingId = null;
        if (closed) _locallyResolved = true;
      });
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            closed
                ? 'Search ended — $awards hunter(s) rewarded. '
                    'Glad your pet is home!'
                : decision == 'Confirmed'
                    ? 'Sighting confirmed.'
                    : 'Marked as not a match.',
          ),
          backgroundColor: const Color(0xFF4CAF7D),
        ),
      );
    } on SightingQueueConflict catch (e) {
      // Their copy of the queue is stale, not wrong. Re-read it and say so
      // plainly instead of showing a red failure they cannot act on.
      if (!mounted) return;
      setState(() => _decidingId = null);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _decidingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _refresh() {
    ref.invalidate(sightingTimelineProvider(widget.petId));
    ref.invalidate(petStatusProvider(widget.petId));
  }

  Future<void> _confirmRescue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End search?'),
        content: const Text(
          'Use this when your pet came back on its own. It ends the search '
          'without rewarding anyone — to reward the hunters who helped, '
          'confirm their sightings instead. You can\'t undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF7D),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isConfirming = true);
    try {
      await ref
          .read(statusTrackerRepositoryProvider)
          .confirmRescue(widget.petId);
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _locallyResolved = true;
      });
      ref.invalidate(sightingTimelineProvider(widget.petId));
      // Re-fetch the authoritative status too so the stepper's RESCUE state
      // is backed by the real DB value, not only the local flag.
      ref.invalidate(petStatusProvider(widget.petId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search ended — glad your pet is home!'),
          backgroundColor: Color(0xFF4CAF7D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Flag a sighting for moderator review. Opens a reason sheet, then POSTs the
  /// chosen reason to `/reports`. Distinct from Reject (an owner "not my pet"
  /// decision) — this is a guideline-violation report to admins.
  Future<void> _reportSighting(SightingActivity item) async {
    const reasons = <String>['Spam', 'Not a pet', 'Inappropriate image'];
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Report this sighting',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            for (final r in reasons)
              ListTile(
                leading:
                    const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: Text(r),
                onTap: () => Navigator.pop(ctx, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    try {
      await ref
          .read(statusTrackerRepositoryProvider)
          .flagSighting(item.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reported for review. Thank you.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullImageView(imageUrl: imageUrl),
      ),
    );
  }

  void _openMap(SightingActivity item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SightingMapView(
          latitude: item.latitude!,
          longitude: item.longitude!,
          title: '${item.detectedSpecies} ${item.actionType}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(sightingTimelineProvider(widget.petId));
    final realStatus = ref.watch(petStatusProvider(widget.petId)).value;
    // Rejected cards stay on the timeline, wearing their badge: the owner said
    // "not mine", which is a decision worth showing back to them, not an
    // entry to hide. Hiding it would also make the queue's order unreadable.
    final items = timelineAsync.value ?? const <SightingActivity>[];
    final resolved = _isResolved(realStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: const Text(
          'STATUS TRACKER',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      // `.noSpinner`: the pull gesture stays, the progress arc goes. The
      // timeline dropping to its skeleton is the refresh feedback.
      body: RefreshIndicator.noSpinner(
        onRefresh: () async => _refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _petHeader(),
            const SizedBox(height: 24),
            StatusStepper(current: _deriveStage(realStatus, items)),
            if (!resolved) ...[
              const SizedBox(height: 16),
              _selfCloseButton(),
            ],
            const SizedBox(height: 28),
            const Text(
              'RECENT ACTIVITY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            timelineAsync.when(
              skipLoadingOnRefresh: false,
              // Use the reject-filtered `items`, not the raw provider data.
              data: (_) => _buildTimeline(items, resolved),
              loading: () => const ActivityTimelineSkeleton(),
              error: (err, _) => _timelineError(err),
            ),
          ],
        ),
      ),
    );
  }

  Widget _petHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 96,
            height: 96,
            child: widget.petImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.petImageUrl!,
                    fit: BoxFit.cover,
                    // Decode to the size actually painted. Image.network
                    // decoded the full 2048px upload into a 96pt box, which
                    // cost ~12 MB of raster cache per photo — about eight of
                    // them filled Flutter's whole 100 MB ImageCache and
                    // started evicting (and re-decoding) on every scroll.
                    memCacheWidth:
                        (96 * MediaQuery.devicePixelRatioOf(context)).round(),
                    placeholder: (_, _) => const Skeletonizer.zone(
                      child: Bone(width: 96, height: 96),
                    ),
                    errorWidget: (_, _, _) => _headerFallback(),
                  )
                : _headerFallback(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.petName.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _headerFallback() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.pets, size: 40, color: Colors.grey),
      );

  Widget _buildTimeline(List<SightingActivity> items, bool resolved) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No sightings reported yet.\nYou\'ll see hunter activity here as it comes in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    final next = resolved ? null : _nextCard(items);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          ActivityCard(
            item: items[i],
            isFirst: i == 0,
            isLast: i == items.length - 1,
            // Exactly one card is actionable at a time — the oldest undecided
            // one. Everything above it waits its turn; everything decided
            // wears a badge instead of buttons.
            showConfirmButton: items[i].id == next?.id,
            isConfirming: _decidingId == items[i].id,
            onConfirm: () => _decide(items[i], 'Confirmed'),
            onReject: items[i].id == next?.id
                ? () => _decide(items[i], 'Rejected')
                : null,
            isLocked: next != null &&
                !items[i].isDecided &&
                items[i].id != next.id,
            onViewMap: items[i].hasLocation ? () => _openMap(items[i]) : null,
            onTapImage: items[i].imageUrl != null
                ? () => _openImage(items[i].imageUrl!)
                : null,
            onReport: () => _reportSighting(items[i]),
          ),
      ],
    );
  }

  /// "My pet came back on its own" — the only way to close a report nobody
  /// else's sighting can close. Deliberately quiet (an outlined button, not the
  /// green one) because it rewards nobody: the loud path is confirming the
  /// hunter who actually brought the animal home.
  Widget _selfCloseButton() {
    return OutlinedButton.icon(
      onPressed: _isConfirming ? null : _confirmRescue,
      icon: const Icon(Icons.home_rounded, size: 18),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4CAF7D),
        side: const BorderSide(color: Color(0xFF4CAF7D)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const StadiumBorder(),
      ),
      label: const Text(
        'MY PET CAME HOME ON ITS OWN',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _timelineError(Object err) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Could not load activity: $err',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                ref.invalidate(sightingTimelineProvider(widget.petId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
