import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/app_config.dart';
import '../../../core/auth/auth_service.dart';
import 'models/lost_pet_post_request.dart';

class LostPetPostRepository {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService;

  LostPetPostRepository(this._authService);

  Map<String, String> get _headers {
    final authToken = _authService.getAuthorizationHeader();
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = authToken;
    }
    return headers;
  }

  /// Ask the AI to guess the pet's species from an already-uploaded photo.
  /// Same endpoint the sightings/camera flow uses — returns the raw decoded
  /// response (`{status, message, data: {species, confidence, bbox}}`).
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

  /// Upload the report photo to Object Storage via FastAPI and return its
  /// public URL. Same generic `/upload/pet-image` endpoint the sightings
  /// flow uses — mirrors `SightingRepository.uploadImage`.
  Future<String> uploadImage(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/pet-image'),
    );

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
      return json['data']['image_url'] as String;
    } else {
      final error = await response.stream.bytesToString();
      throw Exception('Failed to upload image: $error');
    }
  }

  /// Create the missing-pet report — `POST /missing-pets/`
  /// (`PetService.register_missing_pet`). `owner_id` is deliberately absent
  /// from [LostPetPostRequest]; the backend sets it from the JWT.
  ///
  /// Returns the new pet's id. Deliberately does NOT parse the full
  /// `MissingPetModel` — this endpoint returns the raw inserted row (no
  /// RPC projection), and Supabase/PostgREST serializes the `vector` column
  /// (`feature_vector`) as a plain string there, not a JSON array, which
  /// breaks `MissingPetModel`'s generated `List<double>` cast. We don't
  /// need that field here anyway.
  Future<String> createLostPetPost(LostPetPostRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/missing-pets/'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return data['id'] as String;
    } else {
      throw Exception('Failed to submit report: ${response.body}');
    }
  }
}

final lostPetPostRepositoryProvider = Provider<LostPetPostRepository>((ref) {
  final authService = ref.read(authServiceProvider);
  return LostPetPostRepository(authService);
});
