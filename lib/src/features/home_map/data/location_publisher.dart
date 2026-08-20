import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_api.dart';

/// Keeps the hunter's `last_location` fresh on the backend while the app is in
/// use (SRS-23), so a newly reported missing pet can geo-target genuinely
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
/// Singleton so [HomeScreen] can [start] it and logout can [stop] it without
/// provider plumbing — mirrors `FcmService`.
class LocationPublisher {
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
      // `medium` (100 m) not `high` (10 m), with a hard time limit. The
      // consumer is `get_nearby_hunters`, a radius query against a 24 h
      // freshness window — 10 m precision buys it nothing and costs a
      // satellite lock every five minutes. The timeout matters more than it
      // looks: geolocator sets none by default, so a fix that never resolves
      // would leave this future pending while the next tick starts another,
      // stacking one dangling CoreLocation request every 5 minutes.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      await _api.updateMyLocation(position.latitude, position.longitude);
    } catch (e) {
      // Best-effort: a failed publish must not surface to the user.
      debugPrint('[LocationPublisher] publish skipped: $e');
    }
  }
}
