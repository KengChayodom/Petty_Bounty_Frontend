/// The queue moved underneath the owner — the backend's 409.
///
/// A separate type because the recovery is different from every other failure:
/// nothing is wrong with what the owner asked for, their copy of the timeline
/// is simply stale, so the screen re-reads it instead of showing an error.
class SightingQueueConflict implements Exception {
  const SightingQueueConflict(this.message);

  final String message;

  @override
  String toString() => message;
}
