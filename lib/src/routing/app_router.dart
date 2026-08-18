import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/domain/providers/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home_map/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/sightings/presentation/camera_screen.dart';
import '../features/sightings/domain/pending_upload.dart';
import '../features/sightings/presentation/verification_screen.dart';
import '../features/sightings/presentation/matching_results_screen.dart';
import '../features/home_map/presentation/missing_pet_detail_screen.dart';
import '../features/lost_pet_post/presentation/lost_pet_post_screen.dart';
import '../features/status_tracker/presentation/status_tracker_screen.dart';
import 'root_navigator_key.dart';

// Define route paths as constants to prevent typos
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String profile = '/profile';
  static const String camera = '/camera';
  static const String verification = '/verification';
  static const String matchingResults = '/matching-results';
  static const String lostPetPost = '/lost-pet-post';
  static const String statusTracker = '/status-tracker';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = Supabase.instance.client.auth;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    // Re-run `redirect` whenever the session changes (login / logout / refresh).
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      final onAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;

      // Gate every protected screen behind a session.
      if (!loggedIn && !onAuthPage) return AppRoutes.login;
      // Keep authenticated users out of the auth screens.
      if (loggedIn && onAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home Screen with bottom nav
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Profile / Account Screen
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Lost pet post screen
      GoRoute(
        path: AppRoutes.lostPetPost,
        name: 'lost-pet-post',
        builder: (context, state) => const LostPetPostScreen(),
      ),

      // Status Tracker — owner's per-report search progress + sighting
      // timeline. `extra` carries header info (name/photo/resolved) captured at
      // tap time so the header renders without an extra pet-detail fetch.
      GoRoute(
        path: '${AppRoutes.statusTracker}/:petId',
        name: 'status-tracker',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return StatusTrackerScreen(
            petId: state.pathParameters['petId']!,
            petName: args?['petName'] as String? ?? 'Pet',
            petImageUrl: args?['petImageUrl'] as String?,
            isResolved: args?['isResolved'] as bool? ?? false,
          );
        },
      ),

      // Camera Screen. `extra` is null for the home-FAB discovery path, or a
      // {targetPetId, species, petName} map for the pet-detail targeted path.
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return CameraScreen(
            targetPetId: args?['targetPetId'] as String?,
            targetSpecies: args?['species'] as String?,
            targetPetName: args?['petName'] as String?,
          );
        },
      ),

      // Verification Screen. `extra` is a map carrying the captured image path
      // plus the optional targeted-mode fields threaded from the camera.
      GoRoute(
        path: AppRoutes.verification,
        name: 'verification',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return VerificationScreen(
            imagePath: args['imagePath'] as String,
            targetPetId: args['targetPetId'] as String?,
            targetSpecies: args['targetSpecies'] as String?,
            targetPetName: args['targetPetName'] as String?,
            // Upload started back at the shutter press so the transfer overlaps
            // this navigation. Null when the caller didn't pre-start one, in
            // which case the screen uploads on its own.
            pendingUpload: args['pendingUpload'] as PendingUpload?,
          );
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

      // Missing-pet detail — deep-link target for FCM push (SRS-FR-12).
      GoRoute(
        path: '/missing-pets/:petId',
        name: 'missing-pet-detail',
        builder: (context, state) =>
            MissingPetDetailScreen(petId: state.pathParameters['petId']!),
      ),
    ],
  );
});
