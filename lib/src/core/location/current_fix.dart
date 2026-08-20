import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Accuracy to ask for when the app wants a fresh "where am I right now" fix.
///
/// **This is platform-split on purpose, and the Android half is not optional.**
/// geolocator interprets `LocationAccuracy` completely differently per
/// platform:
///
///  * iOS — `LocationAccuracyMapper.m` maps `medium` to
///    `kCLLocationAccuracyHundredMeters` and `high` to `NearestTenMeters`.
///    Both are satisfied from WiFi/cell, so `medium` just answers sooner.
///  * Android — `FusedLocationClient.toPriority` maps `medium` to
///    `PRIORITY_BALANCED_POWER_ACCURACY` and `high` to
///    `PRIORITY_HIGH_ACCURACY`. BALANCED explicitly declines to power up the
///    GPS chip and is served from network/WiFi location only. Where no network
///    fix exists — every Android emulator, and a real handset with WiFi
///    scanning off — the fused provider then emits **nothing at all**:
///    `getCurrentPosition` is `requestLocationUpdates` waiting on a first
///    callback that never arrives, so this presents as `TimeoutException`
///    rather than an error. (Emulator symptom: the map ignores the location
///    you set in Extended Controls, because `adb emu geo fix` feeds the GPS
///    provider and BALANCED never listens to it.)
///
/// So Android must ask for `high` to get the same answer iOS gets from
/// `medium`. The extra precision is not the point and costs nothing here — the
/// position feeds a 10 km radius search, where 10 m versus 100 m cannot change
/// a single result.
LocationAccuracy get currentFixAccuracy =>
    defaultTargetPlatform == TargetPlatform.android
        ? LocationAccuracy.high
        : LocationAccuracy.medium;

/// A fresh position, falling back to the OS's cached one if no new fix arrives
/// within [timeLimit].
///
/// [timeLimit] is mandatory because geolocator configures none by default, and
/// "no fix" is not an exception on either platform — it is an `await` that
/// never completes.
///
/// The fallback is a **real** fix of this user's, just an older one (not the
/// hard-coded default point), so callers may treat it as a genuine position.
/// If there is no cached fix either, the [TimeoutException] is rethrown so the
/// caller can decide between an error and a fallback of its own.
Future<Position> getCurrentFix({required Duration timeLimit}) async {
  try {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: currentFixAccuracy,
      timeLimit: timeLimit,
    );
  } on TimeoutException {
    final cached = await Geolocator.getLastKnownPosition();
    if (cached == null) rethrow;
    return cached;
  }
}
