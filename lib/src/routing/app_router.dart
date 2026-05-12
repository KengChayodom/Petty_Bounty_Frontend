import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/sightings/presentation/camera_screen.dart';
import '../features/sightings/presentation/verification_screen.dart';
// Define route paths as constants to prevent typos
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String verification = '/verification';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true, 
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Map / Home')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.camera),
              child: const Text('Report Sighting (Open Camera)'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),

      GoRoute(
        path: AppRoutes.verification,
        name: 'verification',
        builder: (context, state) {
          final String imagePath = state.extra as String;
          // Return our newly created screen
          return VerificationScreen(imagePath: imagePath);
        },
      ),
    ],
  );
});