// Failures of the bounty flow that the screens react to individually.

/// The report or payment does not exist, or is not the caller's to act on.
class BountyNotFound implements Exception {
  const BountyNotFound(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The request was refused because of the report's or payment's state:
/// already paid, already decided, or the window has closed.
class BountyConflict implements Exception {
  const BountyConflict(this.message);
  final String message;
  @override
  String toString() => message;
}
