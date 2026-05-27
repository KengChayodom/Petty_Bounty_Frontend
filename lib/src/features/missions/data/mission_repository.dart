import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';
import '../../../core/auth/auth_service.dart';
import 'models/mission_model.dart';

class MissionRepository {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService;

  MissionRepository(this._authService);

  Map<String, String> get _headers {
    final authToken = _authService.getAuthorizationHeader();
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = authToken;
    }
    return headers;
  }

  /// Accept a mission (confirm sighting)
  Future<MissionModel> acceptMission(String sightingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/missions/accept/$sightingId'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return MissionModel.fromJson(data);
    } else {
      throw Exception('Failed to accept mission');
    }
  }

  /// Get active missions for the current hunter
  Future<List<MissionModel>> getActiveMissions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/missions/active'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List;
      return data
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get active missions');
    }
  }

  /// Update mission status
  Future<MissionModel> updateMissionStatus({
    required String sightingId,
    required String status,
    String? notes,
  }) async {
    final body = {
      'status': status,
      if (notes != null) 'notes': notes,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/missions/$sightingId/status'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return MissionModel.fromJson(data);
    } else {
      throw Exception('Failed to update mission status');
    }
  }

  /// Get mission history
  Future<List<MissionModel>> getMissionHistory({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/missions/history?limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List;
      return data
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get mission history');
    }
  }
}

/// Provider for MissionRepository
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final authService = ref.read(authServiceProvider);
  return MissionRepository(authService);
});
