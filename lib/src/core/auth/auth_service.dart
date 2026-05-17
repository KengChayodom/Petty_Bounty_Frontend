import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AuthService - COMPLETE AUTH BYPASS FOR TESTING
///
/// ALL authentication logic is DISABLED.
/// Hardcoded user ID is used everywhere.
/// NO Supabase Auth integration.
/// NO Authorization headers sent.
class AuthService {
  // Hardcoded test user ID - used throughout the app
  static const String testUserId = '024dd692-8b4a-44b7-968c-f6f3ddac3f4c';

  /// Bypass: Returns hardcoded user ID
  String getCurrentUserId() => testUserId;

  /// Bypass: Always considered authenticated
  bool get isAuthenticated => true;

  /// Bypass: Sign out does nothing
  Future<void> signOut() async {}

  /// Bypass: Returns null - no auth headers sent
  String? getAuthorizationHeader() => null;
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
