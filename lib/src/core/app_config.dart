import 'dart:io';

class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    // fallback อัตโนมัติถ้าไม่ได้ pass --dart-define
    if (Platform.isAndroid) {
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

  // --- Image capture limits ---------------------------------------------
  //
  // These are a CEILING against a phone dumping an 8 MB 48 MP frame into the
  // pipeline, NOT a compression setting. Do not lower [petImageMaxDimension]
  // to "save bandwidth" — it feeds CLIP matching and the safe floor was
  // measured, not guessed.
  //
  // Why 2048: the backend tight-crops to the YOLO mask and CLIP then resizes
  // that crop to 224x224, so what matters is PIXELS ON THE ANIMAL, not the
  // frame size. Shrinking the source shrinks the crop with it. Measured on
  // the seven seeded pets (cosine of a downscaled photo against the same
  // photo's full-res vector — the vectors already stored in missing_pets):
  //
  //     maxdim 2048 -> min 0.9863   (no visible change; sources are <=2048)
  //     maxdim 1600 -> min 0.9689
  //     maxdim 1280 -> min 0.6419   <- "Nok": mask collapsed, crop 174x262
  //
  // For reference a DIFFERENT photo of the SAME pet scores 0.75-0.95, so at
  // 1280 that bird matched itself worse than a genuine second photo would.
  // 2048 keeps every seeded pet untouched while still capping the outliers.
  static const int petImageMaxDimension = 2048;

  // Profile avatars never reach CLIP — they are only ever displayed small, so
  // they can be capped far harder than a pet photo.
  static const int profileImageMaxDimension = 1024;
}
