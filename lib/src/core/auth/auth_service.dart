import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthService — Feature #6.
///
/// Thin wrapper over Supabase Auth (the one Supabase service the client is
/// allowed to call directly). Registration/login/logout happen here; every
/// FastAPI call then carries the resulting JWT via [getAuthorizationHeader].
class AuthService {
  /// Test seam. Production constructs `AuthService()` and reaches the real
  /// GoTrue client lazily on first use, exactly as before. A test constructs
  /// the subclass it needs — resolving [_auth] is deferred to the getter, so
  /// building the object no longer requires `Supabase.initialize()` to have run.
  AuthService({GoTrueClient? auth}) : _authOverride = auth;

  final GoTrueClient? _authOverride;

  GoTrueClient get _auth => _authOverride ?? Supabase.instance.client.auth;

  /// Register a new Pet Owner / Bounty Hunter. `display_name` and `phone` are
  /// passed as user metadata; the DB trigger `handle_new_user` reads them to
  /// populate the public.users profile row.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phone,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  /// Log in with email + password. Throws [AuthException] on bad credentials.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Log out and clear the persisted session.
  Future<void> signOut() => _auth.signOut();

  /// The current user's id, or null if signed out.
  String? getCurrentUserId() => _auth.currentUser?.id;

  /// Whether a valid session exists.
  bool get isAuthenticated => _auth.currentSession != null;

  /// `Bearer <jwt>` header for FastAPI calls, or null when signed out.
  ///
  /// Read fresh each call so supabase_flutter's silent token refresh is always
  /// honored (never a cached/expired token). Repositories already call this.
  String? getAuthorizationHeader() {
    final token = _auth.currentSession?.accessToken;
    return token != null ? 'Bearer $token' : null;
  }
}

/// Provider for AuthService.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
