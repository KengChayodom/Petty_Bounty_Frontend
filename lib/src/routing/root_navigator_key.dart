import 'package:flutter/widgets.dart';

/// Global navigator key for the root GoRouter. Lives in its own leaf file so
/// non-widget code (e.g. FcmService) can drive navigation for push deep-links
/// without creating an import cycle with app_router.dart.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
