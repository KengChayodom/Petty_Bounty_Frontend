import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_config.dart';
import 'models/sighting_activity.dart';

/// Repository for the Status Tracker screen — reads the sighting timeline for
/// a single missing pet the caller owns.
class StatusTrackerRepository {
  final SupabaseClient _supabase;
  final String _baseUrl;

  StatusTrackerRepository({
    SupabaseClient? supabase,
    String? baseUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        // Same env-aware base URL every other repository uses (handles the
        // Android-emulator-needs-10.0.2.2 case) — never hardcode localhost.
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _authHeaders {
    final token = _supabase.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch the reverse-chronological sighting timeline for [petId] via
  /// `GET /missing-pets/{id}/sightings`. The endpoint already returns newest
  /// first and excludes Dismissed reports (owner-facing filtering is done
  /// server-side), so no client-side sorting/filtering is needed.
  Future<List<SightingActivity>> fetchSightingTimeline(String petId) async {
    final url = Uri.parse('$_baseUrl/missing-pets/$petId/sightings');
    final response = await http.get(url, headers: _authHeaders);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load sighting timeline (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? const [];

    return list
        .map((json) =>
            SightingActivity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the authoritative current status of the report — one of
  /// "Searching", "Spotted", or "Found" — from `GET /missing-pets/{id}`.
  ///
  /// This is what drives the stepper: the real DB state, not a guess inferred
  /// from the sighting timeline. Returns null if the row carries no status.
  Future<String?> fetchPetStatus(String petId) async {
    final url = Uri.parse('$_baseUrl/missing-pets/$petId');
    final response = await http.get(url, headers: _authHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to load pet status (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    return data?['status'] as String?;
  }

  /// Owner marks their own report as resolved by setting `status` -> "Found"
  /// through the general-purpose `PATCH /missing-pets/{id}`.
  ///
  /// NOTE: this is the lightweight self-close path. It does NOT run the
  /// administrator bounty-payout resolution flow (`resolve_missing_pet`, which
  /// needs a transfer slip + reference number). Keep that distinction in mind
  /// before treating this as a full "case closed with reward paid".
  Future<void> confirmRescue(String petId) async {
    final url = Uri.parse('$_baseUrl/missing-pets/$petId');
    final response = await http.patch(
      url,
      headers: _authHeaders,
      body: jsonEncode({'status': 'Found'}),
    );

    if (response.statusCode != 200) {
      String detail = 'Failed to end search (${response.statusCode}).';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        if (err['detail'] != null) detail = err['detail'].toString();
      } catch (_) {}
      throw Exception(detail);
    }
  }
}
