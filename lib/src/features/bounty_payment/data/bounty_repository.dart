import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_config.dart';
import '../../../core/network/app_http_client.dart';
import 'models/bounty_models.dart';

/// The report or payment does not exist, or is not the caller's to act on.
class BountyNotFound implements Exception {
  const BountyNotFound(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The request was refused because of the report's or payment's state:
/// already paid, already decided, or the window has closed.
class BountyConflict implements Exception {
  const BountyConflict(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Feature #6: the owner pays the returning hunter and submits the slip; the
/// hunter confirms, disputes, or refers an unpaid report.
class BountyRepository {
  BountyRepository({
    http.Client? client,
    String? baseUrl,
    String? Function()? authHeader,
    Future<String> Function(String filePath)? uploadSlip,
  })  : _client = client ?? AppHttpClient.instance,
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _authHeader = authHeader ?? _sessionAuthHeader,
        _uploadSlip = uploadSlip ?? _uploadToSlipBucket;

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _authHeader;
  final Future<String> Function(String filePath) _uploadSlip;

  static const String _slipBucket = 'slip-images';

  static String? _sessionAuthHeader() {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      return token == null ? null : 'Bearer $token';
    } catch (_) {
      return null; // Supabase not initialised (tests): send no token.
    }
  }

  /// Uploads straight to Storage, as the sighting photo does. The object name
  /// is random so a slip's URL cannot be guessed; the bucket is public, which
  /// the Limits of the Feature 6 specification record.
  static Future<String> _uploadToSlipBucket(String filePath) async {
    final storage = Supabase.instance.client.storage.from(_slipBucket);
    final ext = filePath.contains('.') ? filePath.split('.').last.toLowerCase() : 'jpg';
    final name = '${const Uuid().v4()}.$ext';
    await storage.upload(
      name,
      File(filePath),
      fileOptions: FileOptions(contentType: lookupMimeType(filePath) ?? 'image/jpeg'),
    );
    return storage.getPublicUrl(name);
  }

  Map<String, String> get _headers {
    final auth = _authHeader();
    return {
      'Content-Type': 'application/json',
      'Authorization': ?auth,
    };
  }

  Object? _data(http.Response r) {
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as Map<String, dynamic>)['data'];
    }
    String message;
    try {
      message = '${(jsonDecode(r.body) as Map<String, dynamic>)['detail']}';
    } catch (_) {
      message = 'Request failed (${r.statusCode}).';
    }
    if (r.statusCode == 404) throw BountyNotFound(message);
    if (r.statusCode == 409) throw BountyConflict(message);
    throw Exception(message);
  }

  /// SRS-104, SRS-105, SRS-107: the payment state of a closed report, with the
  /// hunter's PromptPay number for an owner who owes them.
  Future<BountyView> fetchBounty(String petId) async {
    final r = await _client.get(Uri.parse('$_baseUrl/bounty/$petId'), headers: _headers);
    return BountyView.fromJson(_data(r) as Map<String, dynamic>);
  }

  /// SRS-106: uploads the slip, then submits the payment. Nothing is posted if
  /// the upload fails.
  Future<void> submitPayment(String petId,
      {required String slipPath, String? referenceNo}) async {
    final slipUrl = await _uploadSlip(slipPath);
    final ref = referenceNo?.trim();
    final r = await _client.post(
      Uri.parse('$_baseUrl/bounty/$petId/payment'),
      headers: _headers,
      body: jsonEncode({
        'slip_image_url': slipUrl,
        'reference_no': (ref == null || ref.isEmpty) ? null : ref,
      }),
    );
    _data(r);
  }

  /// SRS-108: the returning hunter confirms the payment or disputes it.
  Future<void> answerPayment(String paymentId, {required bool confirm}) async {
    final r = await _client.post(
      Uri.parse('$_baseUrl/bounty/payments/$paymentId/answer'),
      headers: _headers,
      body: jsonEncode({'answer': confirm ? 'Confirm' : 'Dispute'}),
    );
    _data(r);
  }

  /// SRS-109: the returning hunter refers an unpaid report.
  Future<void> referUnpaid(String petId) async {
    final r = await _client.post(
      Uri.parse('$_baseUrl/bounty/$petId/unpaid'),
      headers: _headers,
    );
    _data(r);
  }

  /// The reports the caller returned the pet for: the hunter's way into
  /// [answerPayment] and [referUnpaid].
  Future<List<HunterBounty>> fetchMyBounties() async {
    final r = await _client.get(Uri.parse('$_baseUrl/bounty/mine'), headers: _headers);
    final list = _data(r) as List<dynamic>? ?? const [];
    return list
        .map((e) => HunterBounty.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
