import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home_map/presentation/home_screen.dart';
import '../features/sightings/presentation/camera_screen.dart';
import '../features/sightings/presentation/verification_screen.dart';
import '../features/sightings/presentation/matching_results_screen.dart';
import '../features/missions/presentation/active_missions_screen.dart';

// Define route paths as constants to prevent typos
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String verification = '/verification';
  static const String matchingResults = '/matching-results';
  static const String activeMissions = '/active-missions';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // Home Screen with bottom nav
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Camera Screen
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),

      // Verification Screen (receives image path)
      GoRoute(
        path: AppRoutes.verification,
        name: 'verification',
        builder: (context, state) {
          final String imagePath = state.extra as String;
          return VerificationScreen(imagePath: imagePath);
        },
      ),

      // Matching Results Screen
      GoRoute(
        path: AppRoutes.matchingResults,
        name: 'matching-results',
        builder: (context, state) {
          final String imagePath = state.extra as String;
          return MatchingResultsScreen(imagePath: imagePath);
        },
      ),

      // Active Missions Screen
      GoRoute(
        path: AppRoutes.activeMissions,
        name: 'active-missions',
        builder: (context, state) => const ActiveMissionsScreen(),
      ),
    ],
  );
});
