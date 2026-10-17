// Failures of the sighting flow that the screens show as the server worded them.

/// The backend refused the sighting for a reason the user can act on, such as
/// a sighting sent on the owner's own report.
class SightingRefused implements Exception {
  const SightingRefused(this.message);
  final String message;
  @override
  String toString() => message;
}
