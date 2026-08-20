import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/app_http_client.dart';
import '../../../../core/app_config.dart';
import '../../domain/entities/missing_pet_entity.dart';
import '../models/missing_pet_model.dart';

/// Repository implementation for fetching missing pets from the backend
class MissingPetRepositoryImpl {
  final String baseUrl = AppConfig.apiBaseUrl;
  final http.Client _client;

  MissingPetRepositoryImpl({http.Client? client})
    : _client = client ?? AppHttpClient.instance;

  /// Fetch nearby missing pets within a radius
  Future<List<MissingPetEntity>> getNearbyMissingPets({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/missing-pets/nearby'
        '?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm',
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List;
      return data
          .map(
            (e) =>
                MissingPetModel.fromJson(e as Map<String, dynamic>).toEntity(),
          )
          .toList();
    } else {
      throw Exception(
        'Failed to get nearby missing pets: ${response.statusCode}',
      );
    }
  }

  /// Get a specific missing pet by ID.
  ///
  /// The backend get_missing_pet_by_id RPC returns the same shape as
  /// /nearby (numeric latitude/longitude projected from the geography,
  /// numeric bounty_amount), so no client-side normalisation is needed.
  Future<MissingPetEntity> getMissingPet(String petId) async {
    final response = await _client.get(Uri.parse('$baseUrl/missing-pets/$petId'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return MissingPetModel.fromJson(data).toEntity();
    } else {
      throw Exception('Failed to get missing pet: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}

// Extension to convert Model to Entity
extension MissingPetModelX on MissingPetModel {
  MissingPetEntity toEntity() {
    return MissingPetEntity(
      id: id,
      ownerId: ownerId,
      petName: petName,
      species: species,
      characteristics: characteristics,
      bountyAmount: bountyAmount,
      latitude: latitude,
      longitude: longitude,
      lastSeenTime: lastSeenTime,
      imageUrl: imageUrl,
      status: status,
      createdAt: createdAt,
      distanceMeters: distanceMeters,
      primaryColorHex: primaryColorHex,
      patternId: patternId,
    );
  }
}
