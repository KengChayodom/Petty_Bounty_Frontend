import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/app_config.dart';
import '../../../core/auth/auth_service.dart';
import 'package:mime/mime.dart';
import 'models/sighting_model.dart';
import 'models/match_model.dart';

class SightingRepository {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService;

  SightingRepository(this._authService);

  Map<String, String> get _headers {
    final authToken = _authService.getAuthorizationHeader();
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = authToken;
    }
    return headers;
  }

  /// Bucket the sighting/pet photos live in. Must match the bucket the
  /// backend's `/upload/pet-image` writes to, because `POST /sightings/analyze`
  /// fetches the resulting public URL server-side.
  static const String _petImageBucket = 'pet-images';

  /// Upload a photo straight to Supabase Storage and return its public URL.
  ///
  /// Storage is one of the three things Flutter is allowed to talk to directly
  /// (Auth, Storage, Realtime) — the golden rule only forbids direct DB access,
  /// and no table is touched here.
  ///
  /// This used to POST the bytes to FastAPI, which then re-uploaded them to
  /// Storage. That made the photo cross the network twice on the way up and
  /// stalled the API's event loop for the whole transfer, because
  /// `supabase.storage.upload()` is a blocking call sitting inside an
  /// `async def` route. Going direct removes both problems; the backend still
  /// downloads the image once, during `/sightings/analyze`.
  ///
  /// NOTE: the `pet-images` bucket has no `file_size_limit` or
  /// `allowed_mime_types` set, so the file-type/10 MB checks that
  /// `/upload/pet-image` performed are NOT enforced on this path. Set those
  /// two bucket properties to restore them — see the deploy note in
  /// `Petty_Bounty_Brain/log.md`.
  Future<String> uploadImage(String filePath) async {
    final storage = Supabase.instance.client.storage.from(_petImageBucket);

    final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
    final extension = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : 'jpg';
    final objectName = '${const Uuid().v4()}.$extension';

    await storage.upload(
      objectName,
      File(filePath),
      fileOptions: FileOptions(contentType: mimeType),
    );
    return storage.getPublicUrl(objectName);
  }

  /// Analyze image with AI to detect species
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sightings/analyze'),
      headers: _headers,
      body: jsonEncode({'image_url': imageUrl}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to analyze image with AI.');
    }
  }

  /// Create a DISCOVERY sighting report.
  ///
  /// The backend's `POST /sightings/` pulls the pre-computed CLIP vector
  /// from the analyze cache, INSERTs the row with the user-confirmed
  /// species, and runs the pgvector match RPC — all in one request. So
  /// this returns BOTH the saved sighting and the ranked matches; the
  /// follow-up `getMatches` call is no longer needed on the hot path.
  ///
  /// The pet-detail *targeted* flow uses [createTargetedSighting] instead —
  /// a separate endpoint, not a flag on this one.
  Future<SightingSubmitResult> createSighting({
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String detectedSpecies,
    String? notes,
  }) async {
    final userId = _authService.getCurrentUserId();

    final body = SightingCreateRequest(
      hunterId: userId!,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      detectedSpecies: detectedSpecies,
      notes: notes,
    ).toJson();

    final response = await http.post(
      Uri.parse('$baseUrl/sightings/'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return SightingSubmitResult.fromJson(data);
    } else {
      throw Exception('Failed to create sighting');
    }
  }

  /// Create a TARGETED sighting report — the hunter is reporting one known
  /// missing pet straight to its owner (from that pet's detail view).
  ///
  /// Hits the dedicated `POST /sightings/targeted` endpoint, which skips AI
  /// species analysis and similarity matching entirely and persists the row
  /// with `initial_target_pet_id` set. Returns the saved sighting with an
  /// empty match list (same response shape as [createSighting]).
  Future<SightingSubmitResult> createTargetedSighting({
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String detectedSpecies,
    required String targetPetId,
    String? notes,
  }) async {
    final userId = _authService.getCurrentUserId();

    final body = <String, dynamic>{
      'hunter_id': userId!,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'detected_species': detectedSpecies,
      'target_pet_id': targetPetId,
      'notes': ?notes,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/sightings/targeted'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return SightingSubmitResult.fromJson(data);
    } else {
      throw Exception('Failed to create targeted sighting');
    }
  }

  /// Get matching missing pets for a sighting
  /// Persist the hunter's final-review choice — 'Spotted' (just saw it) or
  /// 'Caught'/'Rescue' — via `PATCH /sightings/{id}/action`. The backend
  /// normalises UI wording ("Rescue" -> "Caught") itself, so we can pass the
  /// chosen value straight through. Called from the Final Review screen after
  /// the match is confirmed.
  Future<void> confirmSightingAction({
    required String sightingId,
    required String actionType,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sightings/$sightingId/action'),
      headers: _headers,
      body: jsonEncode({'action_type': actionType}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String detail =
          'Failed to confirm report status (${response.statusCode}).';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        if (err['detail'] != null) detail = err['detail'].toString();
      } catch (_) {}
      throw Exception(detail);
    }
  }

  Future<List<MatchModel>> getMatches({
    required String sightingId,
    int limit = 5,
    double radiusKm = 10.0,
    double threshold = 0.7,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/sightings/$sightingId/matches'
        '?limit=$limit&radius_km=$radiusKm&threshold=$threshold',
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final matchesJson = json['matches'] as List;
      return matchesJson
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get matches');
    }
  }

  /// Get a sighting by ID
  Future<SightingModel> getSighting(String sightingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sightings/$sightingId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return SightingModel.fromJson(data);
    } else {
      throw Exception('Failed to get sighting');
    }
  }
}

/// Provider for SightingRepository
final sightingRepositoryProvider = Provider<SightingRepository>((ref) {
  final authService = ref.read(authServiceProvider);
  return SightingRepository(authService);
});
