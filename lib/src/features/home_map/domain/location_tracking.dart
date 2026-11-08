/// Keeping the hunter's location fresh on the backend while the app is in use.
///
/// The contract the screens depend on. `LocationPublisher` (data) implements
/// it, and a test implements it without the geolocator plugin.
abstract interface class LocationTracking {
  /// Idempotent. Starts publishing the device's position.
  void start();

  /// Stops publishing, on logout, so a signed-out user is no longer tracked.
  void stop();
}
