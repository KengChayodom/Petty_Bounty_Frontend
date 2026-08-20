import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_config.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/network/app_http_client.dart';

/// Publishes the hunter's current position to the backend (POST /me/location)
/// so geo-targeted push (SRS-FR-12) can find who is near a newly reported pet.
/// Best-effort and non-blocking — failures are swallowed.
class LocationApi {
  final AuthService _auth = AuthService();
  final http.Client _client = AppHttpClient.instance;

  Future<void> updateMyLocation(double latitude, double longitude) async {
    final authHeader = _auth.getAuthorizationHeader();
    if (authHeader == null) return; // signed out
    try {
      await _client.post(
        Uri.parse('${AppConfig.apiBaseUrl}/me/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );
    } catch (_) {
      // Best-effort: a failed location publish must not disrupt the map.
    }
  }
}
