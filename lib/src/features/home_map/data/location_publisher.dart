import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/location/current_fix.dart';
import 'location_api.dart';

/// Keeps the hunter's `last_location` fresh on the backend while the app is in
/// use (SRS-26), so a newly reported missing pet can geo-target genuinely
/// nearby hunters via `get_nearby_hunters`.
///
/// Design notes (why foreground-only, why a poll):
///  * The backend freshness window for `get_nearby_hunters` is 24 h, so we
///    don't need second-by-second precision — a periodic foreground refresh is
///    enough and avoids background-location permission, battery drain, and the
///    privacy cost of tracking a logged-in user who isn't using the app.
///  * Each tick re-reads GPS, so a hunter who has moved publishes their new
///    position; one who hasn't simply re-stamps the same point.
///  * Best-effort throughout: a failed fix or publish must never disrupt the
///    map. Denied/disabled location => we skip publishing (never push a
///    fallback point, which would cluster denied users at one spot).
///
/// The slice of [LocationPublisher] the logout path needs, kept narrow so a
/// test can implement it without the geolocator plugin.
abstract interface class LocationTracking {
  void stop();
}

/// Injection point for the logout path (MD-34). Production resolves the
/// singleton, so behaviour is unchanged; a test overrides it.
final locationTrackingProvider = Provider<LocationTracking>(
  (ref) => LocationPublisher.instance,
);

/// Singleton so [HomeScreen] can [start] it directly. Logout goes through
/// [locationTrackingProvider] instead — the original note here said the
/// singleton existed so that logout would need no provider plumbing, and that
/// was true until the logout path had to be made verifiable (MD-34, 2126-09-02).
/// Mirrors `FcmService`.
class LocationPublisher implements LocationTracking {
  LocationPublisher._();
  static final LocationPublisher instance = LocationPublisher._();

  final LocationApi _api = LocationApi();
  Timer? _timer;

  /// Foreground refresh cadence. Comfortably inside the 24 h server freshness
  /// window; tuned for "fresh enough" over "real-time".
  static const Duration _interval = Duration(minutes: 5);

  /// Idempotent. Publishes once immediately, then every [_interval].
  void start() {
    if (_timer != null) return;
    _publishOnce();
    _timer = Timer.periodic(_interval, (_) => _publishOnce());
  }

  /// Stop publishing — call on logout (SRS-20) so a signed-out user is no
  /// longer tracked.
  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _publishOnce() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      // The hard time limit matters more than it looks: geolocator sets none
      // by default, so a fix that never resolves would leave this future
      // pending while the next tick starts another, stacking one dangling
      // request every 5 minutes. `getCurrentFix` also falls back to the OS's
      // cached fix on timeout — still a real position of this hunter's, and
      // publishing a slightly stale point is what keeps `get_nearby_hunters`
      // able to see them at all. See `currentFixAccuracy` for why the accuracy
      // asked for is platform-split.
      final position = await getCurrentFix(
        timeLimit: const Duration(seconds: 15),
      );
      await _api.updateMyLocation(position.latitude, position.longitude);
    } catch (e) {
      // Best-effort: a failed publish must not surface to the user.
      debugPrint('[LocationPublisher] publish skipped: $e');
    }
  }
}
