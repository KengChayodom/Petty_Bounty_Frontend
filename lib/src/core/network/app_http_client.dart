import 'package:http/http.dart' as http;

/// The one HTTP client the app makes backend calls through.
///
/// The top-level helpers in `package:http` (`http.get`, `http.post`, …) are
/// documented as creating a [http.Client] and closing it again around every
/// single request, so each call paid a fresh DNS lookup, TCP connect and TLS
/// handshake to a server we were already talking to. On mobile data that is
/// hundreds of milliseconds per request, and it compounded wherever a screen
/// made several calls.
///
/// A single long-lived client keeps the connection pool warm, so everything
/// after the first request reuses an established TLS session.
///
/// A plain static rather than a Riverpod provider on purpose: `FcmService` and
/// `LocationPublisher` are singletons outside the provider graph, and they make
/// backend calls too. Repositories still take an optional client in their
/// constructor, so tests inject a `MockClient` exactly as before.
///
/// Deliberately never closed. Its lifetime is the process's; closing it would
/// break every later request, and the OS reclaims the sockets at exit.
class AppHttpClient {
  AppHttpClient._();

  static final http.Client instance = http.Client();
}
