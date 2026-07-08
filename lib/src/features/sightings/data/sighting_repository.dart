import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';
import '../../../core/auth/auth_service.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
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

  /// Upload pet image to Supabase Storage via FastAPI
  Future<String> uploadImage(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/pet-image'),
    );

    // Add authorization header
    final authToken = _authService.getAuthorizationHeader();
    if (authToken != null) {
      request.headers['Authorization'] = authToken;
    }

    final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
    final mimeTypeSplit = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
      ),
    );

    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData) as Map<String, dynamic>;
      return json['data']['image_url'] as String ?? json['image_url'] as String;
    } else {
      final error = await response.stream.bytesToString();
      throw Exception('Failed to upload image: $error');
    }
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
