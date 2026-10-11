import 'package:supabase_flutter/supabase_flutter.dart';

/// `Bearer <jwt>` for the signed-in user, or null when there is no session.
///
/// Read on every call so a silently refreshed token is always the one sent.
/// [client] is the repository's injected client. Without one the app's
/// Supabase instance is used, and when that has not been initialised (unit
/// tests that build a repository with a fake HTTP client) the call is
/// anonymous rather than a crash.
String? bearerAuthorization([SupabaseClient? client]) {
  final SupabaseClient supabase;
  if (client != null) {
    supabase = client;
  } else {
    try {
      supabase = Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
  final token = supabase.auth.currentSession?.accessToken;
  return token == null ? null : 'Bearer $token';
}

/// Headers for a JSON call to the backend, with the session token when there
/// is one.
Map<String, String> jsonHeaders(String? authorization) => {
      'Content-Type': 'application/json',
      'Authorization': ?authorization,
    };
