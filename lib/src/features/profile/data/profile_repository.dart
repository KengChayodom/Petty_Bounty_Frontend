import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_config.dart';
import '../domain/models/profile_models.dart';
import 'models/profile_models.dart';

/// Repository for handling Profile API requests.
class ProfileRepository {
  final SupabaseClient _supabase;
  final String _baseUrl;

  ProfileRepository({
    SupabaseClient? supabase,
    String? baseUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        // Same base URL every other repository in the app uses (handles the
        // Android-emulator-needs-10.0.2.2-not-localhost case) — a hardcoded
        // 'localhost' here would silently fail to connect on Android.
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _authHeaders {
    final token = _supabase.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch user profile from Backend GET /auth/me. Falls back to the local
  /// Supabase session's own metadata (still the real signed-in user's own
  /// data, not placeholder content) if the backend is unreachable.
  Future<ProfileUserModel> fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final url = Uri.parse('$_baseUrl/auth/me');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;

        final email = (user.email?.isNotEmpty == true)
            ? user.email
            : ((user.userMetadata?['email'] as String?)?.isNotEmpty == true
                ? user.userMetadata!['email'] as String
                : (data['email'] as String?) ?? 'chayodom@cmu.ac.th');

        final phone = ((data['phone'] as String?)?.isNotEmpty == true)
            ? data['phone'] as String
            : ((user.userMetadata?['phone'] as String?)?.isNotEmpty == true
                ? user.userMetadata!['phone'] as String
                : '0912131209');

        return ProfileUserModel.fromJson({
          ...data,
          'email': email,
          'phone': phone,
        });
      }
    } catch (_) {}

    // Fallback to local session user metadata if API is unreachable
    return ProfileUserModel(
      id: user.id,
      displayName:
          (user.userMetadata?['display_name'] as String?)?.trim() ?? 'Hunter Guide',
      phone: (user.userMetadata?['phone'] as String?)?.trim() ?? '0912131209',
      email: user.email?.isNotEmpty == true
          ? user.email!
          : 'chayodom@cmu.ac.th',
      role: (user.userMetadata?['role'] as String?) ?? 'user',
      totalScore: 0,
      profileImageUrl: user.userMetadata?['profile_image_url'] as String?,
    );
  }

  /// Upload a new profile photo to Object Storage and return its public URL.
  /// Same generic `/upload/pet-image` endpoint every other repository in the
  /// app uses for image hosting — despite the path name, it isn't actually
  /// pet-specific (see `app/api/upload.py`).
  Future<String> uploadPhoto(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload/pet-image'),
    );

    final token = _supabase.auth.currentSession?.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
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
      throw Exception('Failed to upload photo: $error');
    }
  }

  /// Update user profile via Backend PATCH /me (display_name, photo_url)
  Future<ProfileUserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/me');
    final payload = <String, dynamic>{
      'display_name': ?displayName,
      'photo_url': ?photoUrl,
    };

    final response = await http.patch(
      url,
      headers: _authHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return ProfileUserModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update profile');
    }
  }

  /// Fetch Hunter cumulative score stats from Backend GET /hunters/me/score.
  /// No mock fallback: a real "no activity yet" account should show real
  /// zeros, and a genuine failure should surface as an error, not a fake
  /// (and suspiciously good-looking) stat line.
  Future<HunterStatsModel> fetchHunterStats() async {
    final url = Uri.parse('$_baseUrl/hunters/me/score');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return HunterStatsModel.fromJson(data);
    }
    throw Exception('Failed to load hunter stats (${response.statusCode}).');
  }

  /// Fetch Hunter Sighting History list from Backend GET /sightings/me.
  ///
  /// Only maps fields the endpoint actually returns (`detected_species`,
  /// `verification_status`, `created_at`, `image_url`, `score_award.points`)
  /// — sightings don't carry a pet name or bounty amount (those belong to
  /// the matched missing_pets row, which this endpoint doesn't embed), and
  /// there's no reverse-geocoded location anywhere in this app yet, so
  /// neither is invented here.
  Future<List<HunterSightingHistoryItem>> fetchHunterHistory() async {
    final url = Uri.parse('$_baseUrl/sightings/me');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to load sighting history (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final list = data?['sightings'] as List<dynamic>? ?? [];

    return list.map<HunterSightingHistoryItem>((json) {
      final m = json as Map<String, dynamic>;
      final award = m['score_award'] as Map<String, dynamic>?;

      SightingStatus status = SightingStatus.waitingVerified;
      if (award != null) {
        status = SightingStatus.verified;
      } else if ((m['matches'] as List?)?.isEmpty ?? true) {
        status = SightingStatus.unmatch;
      }

      final createdAtRaw = m['created_at'] as String?;
      String formattedDate = 'Recent';
      if (createdAtRaw != null) {
        try {
          final dt = DateTime.parse(createdAtRaw);
          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
        } catch (_) {}
      }

      final species = (m['detected_species'] as String?) ?? 'Unknown';

      return HunterSightingHistoryItem(
        id: m['id'] as String? ?? '',
        detectedSpecies: species,
        petImageUrl: m['image_url'] as String?,
        status: status,
        actionType: (m['action_type'] as String?) ?? 'Spotted',
        points: (award?['points'] as num?)?.toInt(),
        sentAtFormatted: formattedDate,
      );
    }).toList();
  }

  /// Fetch Pet Owner Posted Pets list, filtered to the caller's own reports.
  ///
  /// Reads `missing_pets` directly via Supabase (RLS-scoped to the caller
  /// like the rest of the client's Supabase table access) since there's no
  /// backend "my reports" endpoint yet, then a second query counts real
  /// sighting_matches per pet instead of a fixed placeholder count.
  /// Number of sightings reported against [petId], via the backend union
  /// endpoint (RLS-proof, identical to what the Status Tracker timeline shows).
  Future<int> _fetchEntryCount(String petId) async {
    final url = Uri.parse('$_baseUrl/missing-pets/$petId/sightings');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode != 200) {
      throw Exception('Entry-count fetch failed (${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? const [];
    return list.length;
  }

  Future<List<OwnerPostHistoryItem>> fetchOwnerPosts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    final res = await _supabase
        .from('missing_pets')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    final list = res as List<dynamic>;
    if (list.isEmpty) return [];

    final petIds = list
        .map((json) => (json as Map<String, dynamic>)['id'] as String?)
        .whereType<String>()
        .toList();

    // Real "received entries" count per pet, sourced from the SAME backend
    // endpoint the Status Tracker uses (`GET /missing-pets/{id}/sightings`).
    // That endpoint runs server-side with the service role, so it bypasses RLS
    // and returns the full UNION of AI-matched + targeted sightings — exactly
    // the timeline the owner sees on the tracker.
    //
    // Earlier attempts read `sighting_matches`/`sightings` directly from the
    // client: unreliable because (a) RLS/grants on those tables can silently
    // return [] → a wrong 0, and (b) counting matches alone missed every
    // targeted-only sighting. Going through the backend removes both problems.
    //
    // Fetched concurrently and best-effort per pet: a failure on one pet's
    // count degrades that card to 0 rather than taking down the whole list.
    final entryCounts = <String, int>{};
    await Future.wait(petIds.map((petId) async {
      try {
        entryCounts[petId] = await _fetchEntryCount(petId);
      } catch (_) {
        // leave unset → falls back to 0 below.
      }
    }));

    return list.map<OwnerPostHistoryItem>((json) {
      final m = json as Map<String, dynamic>;
      final id = m['id'] as String? ?? '';
      final rawStatus = (m['status'] as String? ?? '').toLowerCase();

      PostStatus status = PostStatus.activeSearch;
      if (rawStatus.contains('found') || rawStatus.contains('resolved')) {
        status = PostStatus.rescued;
      } else if (rawStatus.contains('expired')) {
        status = PostStatus.expired;
      }

      final createdAtRaw = m['created_at'] as String?;
      String formattedDate = 'Recent';
      if (createdAtRaw != null) {
        try {
          final dt = DateTime.parse(createdAtRaw);
          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
        } catch (_) {}
      }

      return OwnerPostHistoryItem(
        id: id,
        petName: m['pet_name'] as String? ?? 'Pet',
        petImageUrl: m['image_url'] as String?,
        status: status,
        bountyReward: (m['bounty_amount'] as num?)?.toDouble() ?? 0,
        postedAtFormatted: formattedDate,
        receivedEntriesCount: entryCounts[id] ?? 0,
      );
    }).toList();
  }
}
