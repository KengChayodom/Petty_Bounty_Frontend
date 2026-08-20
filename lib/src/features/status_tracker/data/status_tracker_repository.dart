import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_config.dart';
import '../../../core/network/app_http_client.dart';
import 'models/sighting_activity.dart';

/// The queue moved underneath the owner — the backend's 409.
///
/// A separate type because the recovery is different from every other failure:
/// nothing is wrong with what the owner asked for, their copy of the timeline
/// is simply stale, so the screen re-reads it instead of showing an error.
class SightingQueueConflict implements Exception {
  const SightingQueueConflict(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Repository for the Status Tracker screen — reads the sighting timeline for
/// a single missing pet the caller owns.
class StatusTrackerRepository {
  final SupabaseClient _supabase;
  final String _baseUrl;
  final http.Client _client;

  StatusTrackerRepository({
    SupabaseClient? supabase,
    String? baseUrl,
    http.Client? client,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _client = client ?? AppHttpClient.instance,
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
    final response = await _client.get(url, headers: _authHeaders);

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
    final response = await _client.get(url, headers: _authHeaders);

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
    final response = await _client.patch(
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

  /// The owner's verdict on one card of their pet's queue, via
  /// `PATCH /missing-pets/{petId}/sightings/{sightingId}`.
  ///
  /// [decision] is 'Confirmed' or 'Rejected'. Confirming a card whose
  /// `action_type` is 'Caught' does far more than record a verdict: it ends the
  /// search and distributes every clue score for the pet. The response says
  /// which happened — `search_closed` and `awards` — so the caller redraws
  /// without a second round-trip.
  ///
  /// Throws [SightingQueueConflict] on 409. That is not a failure the owner
  /// caused: it means the queue moved underneath them (a card was already
  /// decided, an older one is still waiting, or someone closed the search from
  /// another device), and the only sane response is to re-read the timeline.
  Future<Map<String, dynamic>> decideSighting(
    String petId,
    String sightingId,
    String decision,
  ) async {
    final url = Uri.parse('$_baseUrl/missing-pets/$petId/sightings/$sightingId');
    final response = await _client.patch(
      url,
      headers: _authHeaders,
      body: jsonEncode({'decision': decision}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['data'] as Map<String, dynamic>?) ?? const {};
    }

    String detail = 'Failed to record decision (${response.statusCode}).';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      if (err['detail'] != null) detail = err['detail'].toString();
    } catch (_) {}

    if (response.statusCode == 409) throw SightingQueueConflict(detail);
    throw Exception(detail);
  }

  /// Flag a sighting for moderator review via `POST /reports`. [reason] is one
  /// of "Spam" / "Not a pet" / "Inappropriate image" — the backend normalises
  /// the wording onto its `report_reason` enum. The reporter is taken from the
  /// JWT server-side, never sent by the client.
  Future<void> flagSighting(String sightingId, String reason) async {
    final url = Uri.parse('$_baseUrl/reports');
    final response = await _client.post(
      url,
      headers: _authHeaders,
      body: jsonEncode({'sighting_id': sightingId, 'reason': reason}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String detail = 'Failed to report sighting (${response.statusCode}).';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        if (err['detail'] != null) detail = err['detail'].toString();
      } catch (_) {}
      throw Exception(detail);
    }
  }
}
