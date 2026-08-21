import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_config.dart';
import '../../../core/network/app_http_client.dart';
import 'models/rank_models.dart';

/// Reads the two leaderboards (`GET /leaderboard/users` and `/bounties`).
class LeaderboardRepository {
  final SupabaseClient _supabase;
  final String _baseUrl;
  final http.Client _client;

  LeaderboardRepository({
    SupabaseClient? supabase,
    String? baseUrl,
    http.Client? client,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _client = client ?? AppHttpClient.instance,
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _authHeaders {
    final token = _supabase.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// A page of the hunter board plus the caller's own standing. `me` is the
  /// caller's global rank, returned on every page so the pinned row is right
  /// regardless of how far the list has been scrolled.
  Future<UserRankPage> fetchUsers({int limit = 20, int offset = 0}) async {
    final url = Uri.parse(
      '$_baseUrl/leaderboard/users?limit=$limit&offset=$offset',
    );
    final response = await _client.get(url, headers: _authHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to load user leaderboard (${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final entries = (data['entries'] as List<dynamic>? ?? const [])
        .map((e) => RankUser.fromJson(e as Map<String, dynamic>))
        .toList();
    final meJson = data['me'] as Map<String, dynamic>?;
    return UserRankPage(
      entries: entries,
      me: meJson != null ? RankUser.fromJson(meJson) : null,
    );
  }

  /// A page of active missing pets ranked by bounty (highest first).
  Future<List<RankBounty>> fetchBounties({int limit = 20, int offset = 0}) async {
    final url = Uri.parse(
      '$_baseUrl/leaderboard/bounties?limit=$limit&offset=$offset',
    );
    final response = await _client.get(url, headers: _authHeaders);
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load bounty leaderboard (${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return (data['entries'] as List<dynamic>? ?? const [])
        .map((e) => RankBounty.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
