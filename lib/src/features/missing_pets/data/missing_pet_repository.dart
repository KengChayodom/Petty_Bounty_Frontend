import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/network/app_http_client.dart';
import 'models/missing_pet_model.dart';

class MissingPetRepository {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService;
  final http.Client _client;

  MissingPetRepository(this._authService, {http.Client? client})
      : _client = client ?? AppHttpClient.instance;

  Map<String, String> get _headers {
    final authToken = _authService.getAuthorizationHeader();
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = authToken;
    }
    return headers;
  }

  /// Get nearby missing pets within a radius
  Future<List<MissingPetModel>> getNearbyMissingPets({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/missing-pets/nearby'
        '?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm',
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List;
      return data
          .map((e) => MissingPetModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get nearby missing pets');
    }
  }

  /// Get a missing pet by ID
  Future<MissingPetModel> getMissingPet(String petId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/missing-pets/$petId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return MissingPetModel.fromJson(data);
    } else {
      throw Exception('Failed to get missing pet');
    }
  }
}

/// Provider for MissingPetRepository
final missingPetRepositoryProvider = Provider<MissingPetRepository>((ref) {
  final authService = ref.read(authServiceProvider);
  return MissingPetRepository(authService);
});
