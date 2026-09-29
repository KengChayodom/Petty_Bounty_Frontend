import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/app_http_client.dart';
import '../../../../core/app_config.dart';
import '../../domain/entities/missing_pet_entity.dart';
import '../models/missing_pet_model.dart';

/// Repository implementation for fetching missing pets from the backend
class MissingPetRepositoryImpl {
  final String baseUrl = AppConfig.apiBaseUrl;
  final http.Client _client;
  final String? Function() _authHeader;

  MissingPetRepositoryImpl({
    http.Client? client,
    String? Function()? authHeader,
  }) : _client = client ?? AppHttpClient.instance,
       _authHeader = authHeader ?? _sessionAuthHeader;

  /// `Bearer <jwt>` for the signed-in user, or null when there is no session.
  ///
  /// Read on every call so a silently refreshed token is always used. Falls
  /// back to null, meaning "anonymous", when Supabase has not been initialised,
  /// which is the case in unit tests that build this repository with a fake
  /// client.
  static String? _sessionAuthHeader() {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      return token == null ? null : 'Bearer $token';
    } catch (_) {
      return null;
    }
  }

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
    // The backend requires a signed-in caller here, because this response
    // carries the owner's username, phone number and photo. The router already
    // sends a signed-out user to the login screen, so a missing session is not
    // a state this screen reaches.
    final auth = _authHeader();
    final response = await _client.get(
      Uri.parse('$baseUrl/missing-pets/$petId'),
      headers: {'Authorization': ?auth},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      // owner_username / owner_phone are a join the detail endpoint adds
      // on top of the pet row (not part of the pet schema), so read them from
      // the raw payload rather than the model.
      return MissingPetModel.fromJson(data).toEntity(
        ownerUsername: data['owner_username'] as String?,
        ownerPhone: data['owner_phone'] as String?,
        ownerProfileImageUrl: data['owner_profile_image_url'] as String?,
      );
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
  /// [ownerUsername] / [ownerPhone] / [ownerProfileImageUrl] are supplied
  /// only by the by-id detail fetch (see [getMissingPet]); list mappings leave
  /// them null.
  MissingPetEntity toEntity({
    String? ownerUsername,
    String? ownerPhone,
    String? ownerProfileImageUrl,
  }) {
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
      ownerUsername: ownerUsername,
      ownerPhone: ownerPhone,
      ownerProfileImageUrl: ownerProfileImageUrl,
    );
  }
}
