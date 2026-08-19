import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/sighting_activity.dart';
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

  // Sightings the owner marked "not a match" this session. Optimistic and
  // local-only for now — persisting a rejection needs the backend owner_status
  // endpoint (Part B), so these reappear on a refresh until that exists.
  final Set<String> _rejectedIds = <String>{};

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

  Future<void> _confirmRescue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End search?'),
        content: const Text(
          'This marks your pet as found and ends the active search. '
          'You can\'t undo this from here.',
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

  void _rejectSighting(SightingActivity item) {
    // Optimistic local hide. Persisting this (sighting_matches.owner_status =
    // Rejected) requires the Part B backend endpoint — until then it won't
    // survive a refresh.
    setState(() => _rejectedIds.add(item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as not a match.')),
    );
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
    // Locally-rejected sightings drop out of both the timeline and the stepper
    // derivation, so rejecting the only sighting falls back to PENDING.
    final items = (timelineAsync.value ?? const <SightingActivity>[])
        .where((s) => !_rejectedIds.contains(s.id))
        .toList();
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
        onRefresh: () async {
          ref.invalidate(sightingTimelineProvider(widget.petId));
          ref.invalidate(petStatusProvider(widget.petId));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _petHeader(),
            const SizedBox(height: 24),
            StatusStepper(current: _deriveStage(realStatus, items)),
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
                ? Image.network(
                    widget.petImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _headerFallback(),
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

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          ActivityCard(
            item: items[i],
            isFirst: i == 0,
            isLast: i == items.length - 1,
            // A single reported sighting is enough to offer ending the search;
            // the action lives on the most-recent (top) card while still open.
            showConfirmButton: !resolved && i == 0,
            isConfirming: _isConfirming,
            onConfirm: _confirmRescue,
            onReject: (!resolved && i == 0)
                ? () => _rejectSighting(items[i])
                : null,
            onViewMap: items[i].hasLocation ? () => _openMap(items[i]) : null,
            onTapImage: items[i].imageUrl != null
                ? () => _openImage(items[i].imageUrl!)
                : null,
          ),
      ],
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
