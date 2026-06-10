import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../auth/auth_service.dart';
import '../../routing/root_navigator_key.dart';

/// Background / terminated message handler (top-level, vm:entry-point so it
/// survives tree-shaking and runs in its own isolate). A *notification*
/// message is rendered by the OS automatically; we only log here. The tap
/// deep-link is handled by onMessageOpenedApp / getInitialMessage on resume.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM][background] ${message.messageId} data=${message.data}');
}

/// Owns FCM setup for a signed-in user: permission, backend token
/// registration (+ refresh), and the three foreground/tap/terminated states.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final AuthService _auth = AuthService();
  bool _initialized = false;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Idempotent — safe to call on every navigation into Home; the heavy work
  /// runs once per app launch. Called AFTER the location permission flow
  /// settles (see HomeScreen) so the two permission dialogs never race.
  Future<void> initForCurrentUser() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // 1) Foreground → in-app toast (the OS does NOT show a tray banner here).
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) {
        Fluttertoast.showToast(
          msg: '${n.title ?? 'Alert'}: ${n.body ?? ''}',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    });

    // 2) Background tap → deep-link.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);

    // 3) Terminated: app cold-started by tapping the notification.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleDeepLink(initial);

    // Token: fetch, log, register with backend. On iOS this needs the APNs
    // token first; without the APNs key it can be null — that's fine.
    try {
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] token: $token');
        await _registerToken(token);
      } else {
        debugPrint('[FCM] token null (APNs not configured? test on Android)');
      }
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
    }

    // Tokens rotate — re-register on refresh.
    messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] onTokenRefresh: $token');
      _registerToken(token);
    });
  }

  /// POST the token to FastAPI (JWT-protected). No-op if signed out.
  Future<void> _registerToken(String token) async {
    final authHeader = _auth.getAuthorizationHeader();
    if (authHeader == null) {
      debugPrint('[FCM] not signed in — skipping token registration');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/devices/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode({'fcm_token': token, 'platform': _platform}),
      );
      if (res.statusCode != 200) {
        debugPrint('[FCM] register failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[FCM] register error: $e');
    }
  }

  /// Navigate to the pet referenced by the push `data.petId`.
  void _handleDeepLink(RemoteMessage message) {
    final petId = message.data['petId'];
    if (petId == null || petId.isEmpty) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('[FCM] no navigator context yet for deep-link petId=$petId');
      return;
    }
    context.push('/missing-pets/$petId');
  }
}
