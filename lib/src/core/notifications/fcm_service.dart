import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../auth/auth_service.dart';
import '../network/app_http_client.dart';
import '../../routing/root_navigator_key.dart';

/// Background / terminated message handler (top-level, vm:entry-point so it
/// survives tree-shaking and runs in its own isolate). A *notification*
/// message is rendered by the OS automatically; we only log here. The tap
/// deep-link is handled by onMessageOpenedApp / getInitialMessage on resume.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM][background] ${message.messageId} data=${message.data}');
}

/// The slice of [FcmService] the logout path needs, kept narrow on purpose: a
/// test can implement one method, where it could not build an [FcmService] at
/// all — the constructor is private and the class reaches the Firebase plugin.
abstract interface class PushRegistration {
  Future<void> unregisterForCurrentUser();
}

/// Injection point for the logout path (MD-34). Production resolves the
/// singleton, so behaviour is unchanged; a test overrides it. Every other
/// caller still reaches [FcmService.instance] directly — only the path that
/// needed to be verifiable was routed through a provider.
final pushRegistrationProvider = Provider<PushRegistration>(
  (ref) => FcmService.instance,
);

/// Owns FCM setup for a signed-in user: permission, backend token
/// registration (+ refresh), and the three foreground/tap/terminated states.
class FcmService implements PushRegistration {
  FcmService._();
  static final FcmService instance = FcmService._();

  final AuthService _auth = AuthService();

  /// Shared with every repository — keeps the TLS connection to the
  /// backend warm instead of handshaking again per token sync.
  final http.Client _client = AppHttpClient.instance;

  /// Guards the ONE-TIME half of setup (permission prompt + stream listeners).
  /// Deliberately NOT a guard on token registration — see [syncToken].
  bool _initialized = false;

  /// The token this app run has successfully registered with the backend.
  /// Null after a failed attempt, so the next [syncToken] retries instead of
  /// assuming success. This is what makes registration self-healing: the old
  /// code set an `_initialized` flag *before* registering, so a single silent
  /// no-op (signed out, null token, HTTP error) meant no token for the whole
  /// process — the cause of most users having no row in `device_tokens`.
  String? _lastRegisteredToken;

  // Held so logout can tear them down — otherwise a logout→login on the same
  // app run would stack duplicate listeners (double toasts, double deep-links).
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Idempotent — safe to call on every navigation into Home; the heavy work
  /// runs once per app launch. Called AFTER the location permission flow
  /// settles (see HomeScreen) so the two permission dialogs never race.
  Future<void> initForCurrentUser() async {
    final messaging = FirebaseMessaging.instance;

    // The one-time half: prompting and subscribing more than once would stack
    // duplicate listeners (double toasts, double deep-links). The token half
    // below runs on EVERY call.
    if (!_initialized) {
      _initialized = true;
      await _setUpOnce(messaging);
    }

    await syncToken();
  }

  /// Permission prompt + the three delivery states. Runs once per app run.
  Future<void> _setUpOnce(FirebaseMessaging messaging) async {
    final settings = await messaging.requestPermission();
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // 1) Foreground → in-app toast (the OS does NOT show a tray banner here).
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) {
        Fluttertoast.showToast(
          msg: '${n.title ?? 'Alert'}: ${n.body ?? ''}',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    });

    // 2) Background tap → deep-link.
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);

    // 3) Terminated: app cold-started by tapping the notification.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleDeepLink(initial);

    // Tokens rotate — re-register on refresh.
    _onTokenRefreshSub = messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] onTokenRefresh: $token');
      _lastRegisteredToken = null; // the old one is stale; force a real POST
      syncToken();
    });
  }

  /// Fetch this device's FCM token and make sure the backend has it.
  ///
  /// Safe and cheap to call as often as you like — call it on **every app
  /// startup, every successful login, and every resume**. A token that is
  /// already registered this app run costs nothing; anything else is one POST.
  ///
  /// Does NOT prompt for permission, so it never races the location dialog
  /// (`getToken()` prompts on neither platform; on iOS it simply returns null
  /// until APNs is ready). That is why it is safe to call from startup while
  /// the permission prompt stays where it is, after the location flow.
  ///
  /// A no-op while signed out — `/devices/register` is JWT-scoped, and the
  /// row must belong to the right user.
  Future<void> syncToken() async {
    // Reading the session can throw where Supabase was never initialised (a
    // widget test, or a very early startup failure). The callers treat this
    // method as fire-and-forget — `LoginScreen._submit` does not await it — so
    // an escaping error would surface as an unhandled async exception rather
    // than as anything a user could act on. Not knowing whether we are signed
    // in is treated the same as being signed out: skip.
    final String? authHeader;
    try {
      authHeader = _auth.getAuthorizationHeader();
    } catch (e) {
      debugPrint('[FCM] auth unavailable — skipping token sync: $e');
      return;
    }
    if (authHeader == null) {
      debugPrint('[FCM] not signed in — skipping token sync');
      return;
    }

    final String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return;
    }
    if (token == null) {
      debugPrint('[FCM] token null (APNs not configured? test on Android)');
      return;
    }

    if (token == _lastRegisteredToken) return;

    // Only remember it once the backend has actually taken it, so a failed
    // POST is retried on the next startup/login/resume rather than assumed.
    if (await _registerToken(token)) {
      _lastRegisteredToken = token;
      debugPrint('[FCM] token registered: ${token.substring(0, 12)}...');
    }
  }

  /// Tear down push for the user who is logging out (SRS-20).
  ///
  /// MUST be called BEFORE `auth.signOut()` so the backend delete still carries
  /// a valid JWT. Order matters: drop the server row first, then invalidate the
  /// token on-device so this handset stops receiving alerts entirely, then
  /// cancel listeners and reset so the next login re-initialises cleanly.
  @override
  Future<void> unregisterForCurrentUser() async {
    final messaging = FirebaseMessaging.instance;
    try {
      final token = await messaging.getToken();
      if (token != null) await _unregisterToken(token);
    } catch (e) {
      debugPrint('[FCM] getToken on logout failed: $e');
    }

    // Invalidate the FCM token on this device. After this the old token is dead
    // server-side at FCM too, so a stray push can't reach the logged-out user.
    try {
      await messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] deleteToken failed: $e');
    }

    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onOpenedSub = null;
    _onTokenRefreshSub = null;
    _initialized = false;
    _lastRegisteredToken = null;
  }

  /// DELETE the token row at FastAPI (JWT-protected). No-op if signed out.
  Future<void> _unregisterToken(String token) async {
    final authHeader = _auth.getAuthorizationHeader();
    if (authHeader == null) {
      debugPrint('[FCM] not signed in — skipping token unregister');
      return;
    }
    try {
      final res = await _client.post(
        Uri.parse('${AppConfig.apiBaseUrl}/devices/unregister'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode({'fcm_token': token}),
      );
      if (res.statusCode != 200) {
        debugPrint('[FCM] unregister failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[FCM] unregister error: $e');
    }
  }

  /// POST the token to FastAPI (JWT-protected). Returns whether the backend
  /// accepted it — the caller memoises on true only, so a failure retries.
  Future<bool> _registerToken(String token) async {
    final authHeader = _auth.getAuthorizationHeader();
    if (authHeader == null) {
      debugPrint('[FCM] not signed in — skipping token registration');
      return false;
    }
    try {
      final res = await _client.post(
        Uri.parse('${AppConfig.apiBaseUrl}/devices/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode({'fcm_token': token, 'platform': _platform}),
      );
      if (res.statusCode != 200) {
        debugPrint('[FCM] register failed: ${res.statusCode} ${res.body}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[FCM] register error: $e');
      return false;
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
