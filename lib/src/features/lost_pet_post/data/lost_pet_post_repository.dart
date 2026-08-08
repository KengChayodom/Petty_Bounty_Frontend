import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/app_config.dart';
import '../../../core/auth/auth_service.dart';

class LostPetPostRepository {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService;

  LostPetPostRepository(this._authService);

  /// Upload the report photo to Object Storage via FastAPI and return its
  /// public URL. Same generic `/upload/pet-image` endpoint the sightings
  /// flow uses — mirrors `SightingRepository.uploadImage`.
  Future<String> uploadImage(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/pet-image'),
    );

    final authToken = _authService.getAuthorizationHeader();
    if (authToken != null) {
      request.headers['Authorization'] = authToken;
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
      throw Exception('Failed to upload image: $error');
    }
  }
}

final lostPetPostRepositoryProvider = Provider<LostPetPostRepository>((ref) {
  final authService = ref.read(authServiceProvider);
  return LostPetPostRepository(authService);
});
