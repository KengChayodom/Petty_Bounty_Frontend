import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_glass.dart';
import '../../../core/ui/brand_widgets.dart';
import '../../../routing/app_router.dart';
import '../domain/entities/sighting_activity.dart';
import '../domain/entities/sighting_queue_conflict.dart';
import '../domain/providers/status_tracker_providers.dart';
import '../../profile/domain/providers/profile_providers.dart';
import 'widgets/activity_card.dart';
import 'widgets/activity_timeline_skeleton.dart';
import '../../../core/ui/full_image_view.dart';
import 'widgets/sighting_map_view.dart';
import 'widgets/status_stepper.dart';
import '../../bounty_payment/presentation/owner_bounty_section.dart';

/// Owner-facing "Status Tracker" screen: the search progress of a single lost
/// pet report — a 4-stage stepper plus the chronological sighting timeline
/// (oldest first, top to bottom). Reached from the Profile → Owner tab by
/// tapping a report card.
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

/// `post_status` values as the backend spells them, lower-cased for comparison.
/// See `app/services/pet_logic.py` — that module owns the rule; these are only
/// the four words it can answer with.
const String _postStatusPending = 'pending';
const String _postStatusSpotted = 'spotted';
const String _postStatusExpired = 'expired';
const String _postStatusRescued = 'rescued';

class _StatusTrackerScreenState extends ConsumerState<StatusTrackerScreen> {
  bool _isConfirming = false;
  // Flips to true once the owner ends the search from this screen, so the
  // stepper jumps to RESCUE and the confirm button disappears without needing
  // a full re-fetch round-trip.
  bool _locallyResolved = false;

  // The card a decision is currently in flight for, so only that card's
  // buttons go busy rather than every card at once.
  String? _decidingId;

  // True only while an explicit pull-to-refresh is in flight. It decides
  // whether a re-fetch is allowed to drop the timeline to its skeleton.
  //
  // The skeleton is two placeholder cards. Substituting it for a timeline of
  // ten collapses the scrollable's extent, which clamps the scroll offset —
  // and the offset does not come back when the real cards do. So every
  // confirm/reject threw the owner back to the top of the list, away from the
  // card they had just ruled on and the one they were about to. A pull gesture
  // can only start at the top, so there the collapse costs nothing and the
  // skeleton stays: it is the only feedback `RefreshIndicator.noSpinner` gives.
  bool _pullRefreshing = false;

  /// Whether the report is resolved. `_locallyResolved` (this session's own
  /// end-search tap) always wins; otherwise the backend's derived badge
  /// decides, falling back to the seed passed in only while it's still loading.
  ///
  /// "Rescued" covers BOTH ways a search ends — the owner closing it (`Found`)
  /// and the administrator settling the bounty afterwards (`Resolved`). This
  /// used to test the raw column for `found` alone, so a case whose money had
  /// moved reopened itself on screen.
  bool _isResolved(String? postStatus) {
    if (_locallyResolved) return true;
    if (postStatus == null) return widget.isResolved;
    return postStatus.toLowerCase() == _postStatusRescued;
  }

  /// Stepper stage, mapped 1:1 from the backend's `post_status`:
  ///   RESCUE  — "Rescued": the search has ended (owner closed it, or the
  ///             bounty was settled afterwards).
  ///   SPOTTED — "Spotted": at least one sighting counts towards this pet.
  ///   PENDING — "Pending" or "Expired": nothing has come in. An expired post
  ///             has made no progress by definition, so it sits on the same
  ///             step; the EXPIRED wording belongs on the report card, not on a
  ///             progress bar.
  ///   LOST    — the base step; always lit beneath whichever is current, so it
  ///             is never returned as the "current" stage (a post always
  ///             exists once this screen is open).
  ///
  /// The rule behind those words lives in `pet_logic.derive_post_status` and is
  /// deliberately NOT reimplemented here — this screen used to own a second
  /// copy that counted raw timeline entries, which double-counted a sighting
  /// that was both AI-matched and hunter-targeted and still counted matches the
  /// owner had rejected.
  ///
  /// `postStatus` is null only while the backend fetch is in flight (or if the
  /// backend is older than the field); the seed and the timeline cover that
  /// window so the stepper doesn't flash.
  TrackerStage _deriveStage(String? postStatus, List<SightingActivity> items) {
    if (_locallyResolved) return TrackerStage.rescue;

    switch (postStatus?.toLowerCase()) {
      case _postStatusRescued:
        return TrackerStage.rescue;
      case _postStatusSpotted:
        return TrackerStage.spotted;
      case _postStatusPending:
      case _postStatusExpired:
        return TrackerStage.pending;
    }

    // Nothing authoritative yet — hold the seed rather than flashing a stage.
    if (widget.isResolved) return TrackerStage.rescue;
    return items.isNotEmpty ? TrackerStage.spotted : TrackerStage.pending;
  }

  /// The one card the owner may act on: the OLDEST still-undecided card.
  ///
  /// [items] is oldest-first here, so that is the first Pending entry in it.
  /// The rule is enforced by the backend (409) — this only keeps the screen
  /// from offering a button that would be refused. Its purpose is that nobody
  /// who helped is skipped over on the way to closing the case: scoring counts
  /// confirmed cards only, so a card left Pending earns its hunter nothing.
  SightingActivity? _nextCard(List<SightingActivity> items) {
    for (final item in items) {
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
                backgroundColor: kBrandDeep,
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
          backgroundColor: kSuccessDeep,
        ),
      );
    } on SightingQueueConflict catch (e) {
      // Their copy of the queue is stale, not wrong. Re-read it and say so
      // plainly instead of showing a red failure they cannot act on.
      if (!mounted) return;
      setState(() => _decidingId = null);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _decidingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: kBrandErrorDeep),
      );
    }
  }

  void _refresh() {
    ref.invalidate(sightingTimelineProvider(widget.petId));
    ref.invalidate(petPostStatusProvider(widget.petId));
    // Also drop the Profile screen's owner-posts cache so its status badge
    // (ACTIVE SEARCH → RESCUED, etc.) is re-fetched on the next visit instead
    // of showing a stale value. The provider is autoDispose so this is a no-op
    // when the Profile screen is not in the tree — safe to call either way.
    ref.invalidate(ownerPostsProvider);
  }

  /// Pull-to-refresh: the same re-fetch, but flagged so the timeline is allowed
  /// to show its skeleton, and awaited so the flag is only cleared once the new
  /// data has landed.
  Future<void> _pullToRefresh() async {
    setState(() => _pullRefreshing = true);
    _refresh();
    try {
      await ref.read(sightingTimelineProvider(widget.petId).future);
    } catch (_) {
      // A failed re-fetch is the `error:` branch's story to tell; all this
      // needs to do either way is stop suppressing the data.
    }
    if (mounted) setState(() => _pullRefreshing = false);
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
              backgroundColor: kBrandDeep,
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
      ref.invalidate(petPostStatusProvider(widget.petId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search ended — glad your pet is home!'),
          backgroundColor: kSuccessDeep,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: kBrandErrorDeep),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            for (final r in reasons)
              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: kBrandErrorDeep,
                ),
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
        const SnackBar(content: Text('Reported for review. Our moderators will take a look.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: kBrandErrorDeep),
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
    // `.valueOrNull`, not `.value`: the latter RE-THROWS when the provider is
    // in its error state (e.g. the backend connection dropped), which would
    // crash `build` before the `timelineAsync.when(error: ...)` branch below
    // gets a chance to render the retry UI.
    final postStatus = ref
        .watch(petPostStatusProvider(widget.petId))
        .valueOrNull;
    // Rejected cards stay on the timeline, wearing their badge: the owner said
    // "not mine", which is a decision worth showing back to them, not an
    // entry to hide. Hiding it would also make the queue's order unreadable.
    //
    // The endpoint hands back newest-first; flip it to oldest-first so the
    // timeline reads top-to-bottom in the order things happened and the card
    // the owner acts on next — the oldest undecided one — sits at the top
    // instead of at the very bottom of a long scroll.
    final items = (timelineAsync.valueOrNull ?? const <SightingActivity>[])
        .reversed
        .toList(growable: false);
    final resolved = _isResolved(postStatus);

    return PhotoHeroScaffold(
      imageUrl: widget.petImageUrl,
      title: widget.petName,
      subtitle: resolved ? 'Home. The search has ended.' : 'Still searching',
      onRefresh: _pullToRefresh,
      actions: [
        // Edit the report's name / bounty / colour / traits. Hidden once the
        // search has ended — there is nothing left to edit then.
        if (!resolved)
          GlassIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit report',
            onPressed: () async {
              final changed = await context.push<bool>(
                '${AppRoutes.lostPetPostEdit}/${widget.petId}',
              );
              if (changed == true && mounted) _refresh();
            },
          ),
      ],
      children: [
        StatusStepper(current: _deriveStage(postStatus, items)),
        if (!resolved) ...[
          const SizedBox(height: 18),
          _selfCloseButton(),
        ],
        // Once the search has ended, the bounty is settled here.
        if (resolved) ...[
          const SizedBox(height: 20),
          OwnerBountySection(petId: widget.petId),
        ],
        const SizedBox(height: 28),
        const SheetHeading('Sightings'),
        const SizedBox(height: 14),
        timelineAsync.when(
          // Keep the cards on screen through a decision's re-fetch, and only
          // through that one — see `_pullRefreshing`. The first load is
          // unaffected either way: with no previous value to keep, `loading:`
          // runs regardless and the skeleton still shows.
          skipLoadingOnRefresh: !_pullRefreshing,
          data: (_) => _buildTimeline(items, resolved),
          loading: () => const ActivityTimelineSkeleton(),
          error: (err, _) => _timelineError(err),
        ),
      ],
    );
  }

  Widget _buildTimeline(List<SightingActivity> items, bool resolved) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: kInk.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No sightings reported yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: kInk.withValues(alpha: 0.65), fontSize: 14),
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
            // Keyed by sighting id so a re-fetch re-uses each card's existing
            // element (and its already-decoded photo) instead of rebuilding
            // the column from scratch under the owner's scroll position.
            key: ValueKey(items[i].id),
            item: items[i],
            isFirst: i == 0,
            isLast: i == items.length - 1,
            // Exactly one card is actionable at a time — the oldest undecided
            // one. Everything below it waits its turn; everything above is
            // already decided and wears a badge instead of buttons.
            showConfirmButton: items[i].id == next?.id,
            isConfirming: _decidingId == items[i].id,
            onConfirm: () => _decide(items[i], 'Confirmed'),
            onReject: items[i].id == next?.id
                ? () => _decide(items[i], 'Rejected')
                : null,
            isLocked:
                next != null && !items[i].isDecided && items[i].id != next.id,
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
    return BrandButton(
      label: 'My pet came home on its own',
      icon: Icons.home_rounded,
      outlined: true,
      onPressed: _isConfirming ? null : _confirmRescue,
    );
  }

  Widget _timelineError(Object err) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: kBrandErrorDeep, size: 32),
          const SizedBox(height: 8),
          Text(
            'Could not load the sightings. Check your connection, then try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kBrandErrorDeep),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                ref.invalidate(sightingTimelineProvider(widget.petId)),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
