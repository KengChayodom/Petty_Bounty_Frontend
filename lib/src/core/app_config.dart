import 'dart:io';

class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    // fallback อัตโนมัติถ้าไม่ได้ pass --dart-define
    if (Platform.isAndroid){
      // return 'http://10.0.2.2:8000';
      return 'http://192.168.1.50:8000';
      
      }
    return 'http://127.0.0.1:8000'; // iOS/Mac
  }
}