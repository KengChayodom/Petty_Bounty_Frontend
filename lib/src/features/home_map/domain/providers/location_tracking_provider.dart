import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location_publisher.dart';
import '../location_tracking.dart';

/// Injection point for the home screen (start) and the logout path (stop,
/// MD-34). Production resolves the singleton, a test overrides it.
final locationTrackingProvider = Provider<LocationTracking>(
  (ref) => LocationPublisher.instance,
);
