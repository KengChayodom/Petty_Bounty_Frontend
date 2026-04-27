import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define route paths as constants to prevent typos
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String verification = '/verification';
}

// Create a Provider for GoRouter so we can access it anywhere
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true, // Prints routing info in the console
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
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Camera Sighting')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.verification),
              child: const Text('Mock Take Photo -> Go to Verification'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.verification,
        name: 'verification',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('AI Verification')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Confirm & Go Home'),
            ),
          ),
        ),
      ),
    ],
  );
});