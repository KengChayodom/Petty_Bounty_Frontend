import 'dart:io';

class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    // fallback อัตโนมัติถ้าไม่ได้ pass --dart-define
    if (Platform.isAndroid){
      // return 'http://10.0.2.2:8000';
      return 'http://10.0.2.2:8000';

      }
    return 'http://127.0.0.1:8000'; // iOS/Mac
  }

  // --- Supabase (Auth / Storage / Realtime only — never DB CRUD) ---
  // Override per-build with:
  //   --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  // The publishable/anon key is designed to be shipped in the client, so the
  // dev fallback below is safe to embed.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gleqzpqdoadmtckuegax.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_xOgeiJ_LsWHDt04AichbsQ_XWYad3di',
  );
}
