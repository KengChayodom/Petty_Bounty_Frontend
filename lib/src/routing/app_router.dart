import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/domain/providers/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home_map/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/sightings/presentation/camera_screen.dart';
import '../features/sightings/presentation/verification_screen.dart';
import '../features/sightings/presentation/matching_results_screen.dart';
import '../features/missions/presentation/active_missions_screen.dart';
import '../features/home_map/presentation/missing_pet_detail_screen.dart';
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
  static const String activeMissions = '/active-missions';
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
      final onAuthPage =
          loc == AppRoutes.login || loc == AppRoutes.register;

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
