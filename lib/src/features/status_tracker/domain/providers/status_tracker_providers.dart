import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sighting_activity.dart';
import '../../data/status_tracker_repository.dart';

/// DI seam for the Status Tracker repository (overridable in tests).
final statusTrackerRepositoryProvider =
    Provider<StatusTrackerRepository>((ref) => StatusTrackerRepository());

/// Sighting timeline for a single pet, keyed by its id.
///
/// autoDispose so leaving the screen drops the cache — a re-open (or a
/// pull-to-refresh via `ref.invalidate`) always re-fetches fresh activity
/// rather than showing a stale timeline.
final sightingTimelineProvider = FutureProvider.autoDispose
    .family<List<SightingActivity>, String>((ref, petId) async {
  final repo = ref.watch(statusTrackerRepositoryProvider);
  return repo.fetchSightingTimeline(petId);
});

/// The backend's derived badge for a report ("Pending" | "Spotted" |
/// "Expired" | "Rescued"), keyed by pet id. This — not the timeline, and not
/// the raw `status` column — is the source of truth for the stepper's current
/// stage. autoDispose + invalidated after an end-search so the stepper
/// reflects the server's answer rather than a local guess.
final petPostStatusProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, petId) async {
  final repo = ref.watch(statusTrackerRepositoryProvider);
  return repo.fetchPostStatus(petId);
});
